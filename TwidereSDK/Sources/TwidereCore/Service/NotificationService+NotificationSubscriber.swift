//
//  NotificationService+NotificationViewModel.swift
//  
//
//  Created by MainasuK on 2022-7-6.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import TwidereCommon

public struct NotificationSubject {
    public let fcmToken: String?
    public let appSecret: AppSecret
}

public protocol NotificationSubscriber {
    var userIdentifier: UserIdentifier { get }
    func update(api: APIService, subject: NotificationSubject)
}

extension NotificationService {
    final public class MastodonNotificationSubscriber: NotificationSubscriber {
        
        let logger = Logger(subsystem: "MastodonNotificationSubscriber", category: "Subscriber")
        
        var disposeBag = Set<AnyCancellable>()
        
        // input
        public let userIdentifier: UserIdentifier
        public let authenticationContext: MastodonAuthenticationContext
        
        init(authenticationContext: MastodonAuthenticationContext) {
            self.userIdentifier = .mastodon(.init(domain: authenticationContext.domain, id: authenticationContext.userID))
            self.authenticationContext = authenticationContext
            // end init
        }
        
        
        public func update(api: APIService, subject: NotificationSubject) {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update subscription for \(String(describing: self.userIdentifier))")
            
            Task {
                do {
                    try await self.subscribe(api: api, subject: subject)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): subscribe notification success")

                } catch {
                    guard subject.fcmToken != nil else {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): subscribe notification: wait device token…")
                        return
                    }
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): subscribe notification fail: \(error.localizedDescription)")
                }
            }   // end
        }
    }
}

extension NotificationService.MastodonNotificationSubscriber {
    private func subscribe(
        api: APIService,
        subject: NotificationSubject
    ) async throws {
        let authenticationContext = self.authenticationContext

        // precondition: valid fmcToken
        guard let token = subject.fcmToken else {
            throw AppError.implicit(.badRequest)
        }
        
        // use isolated context to delay object saving
        // so update before saving without persistence coordinator sync possible
        let managedObjectContext = api.coreDataStack.newTaskContext()
        let notificationSubscriptionRecord = try await createOrFetchNotificationSubscription(managedObjectContext: managedObjectContext)

        let subscription: Mastodon.API.Push.QuerySubscription = {
            let appSecret = subject.appSecret
            let endpoint = appSecret.mastodonNotificationRelayEndpoint + "/" + token
            let p256dh = appSecret.mastodonNotificationPublicKey.x963Representation
            let auth = appSecret.mastodonNotificationAuth
            return .init(
                endpoint: endpoint,
                keys: .init(
                    p256dh: p256dh,
                    auth: auth
                )
            )
        }()
        
        do {
            // request server relay push notification on endpoint
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] subscribe notification on \(subscription.endpoint)…")
            
            let _query: Mastodon.API.Push.CreateSubscriptionQuery? = try await managedObjectContext.perform {
                guard let notificationSubscription = notificationSubscriptionRecord.object(in: managedObjectContext) else {
                    assertionFailure()
                    throw AppError.implicit(.internal(reason: "precondition: valid subscription record"))
                }
                guard notificationSubscription.isActive else {
                    return nil
                }
                return .init(
                    subscription: subscription,
                    data: .init(alerts: .init(
                        favourite: notificationSubscription.favourite,
                        follow: notificationSubscription.follow,
                        reblog: notificationSubscription.reblog,
                        mention: notificationSubscription.mention,
                        poll: notificationSubscription.poll
                    ))
                )
            }
            guard let query = _query else {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] cancel notification subscription…")
                _ = try await api.cancelMastodonNotificationSubscription(
                    authenticationContext: authenticationContext
                )
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] cancel notification subscription success")
                return
            }

            let response = try await api.createMastodonNotificationSubscription(
                query: query,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] subscribe notification on \(subscription.endpoint) success. Settings:\n\(String(describing: response.value))")
            
            // update and save the notification subscription object
            try? await managedObjectContext.performChanges {
                guard let notificationSubscription = notificationSubscriptionRecord.object(in: managedObjectContext) else {
                    return
                }
                let subscription = response.value
                notificationSubscription.update(domain: authenticationContext.domain)
                notificationSubscription.update(id: subscription.id)
                notificationSubscription.update(endpoint: subscription.endpoint)
                notificationSubscription.update(serverKey: subscription.serverKey)
                notificationSubscription.update(userToken: authenticationContext.authorization.accessToken)
                notificationSubscription.update(updatedAt: Date())
                
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] update notification subscription")
            }
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] subscribe notification on \(subscription.endpoint) failure: \(error.localizedDescription)")
            
            // save the placeholder notification subscription object
            // allow user update preference in settings
            // and retry subscribe at the nexta app launch
            try? await managedObjectContext.performChanges {
                guard let notificationSubscription = notificationSubscriptionRecord.object(in: managedObjectContext) else {
                    return
                }
                notificationSubscription.update(updatedAt: Date())
                
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [PUSH] update notification subscription")
            }
            
            throw error
        }
    }
    
    private func createOrFetchNotificationSubscription(
        managedObjectContext: NSManagedObjectContext
    ) async throws -> ManagedObjectRecord<MastodonNotificationSubscription> {
        let authenticationContext = self.authenticationContext
        
        var _record: ManagedObjectRecord<MastodonNotificationSubscription>? = await managedObjectContext.perform {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let notificationSubscription = authentication.notificationSubscription
            else {
                return nil
            }
            return .init(objectID: notificationSubscription.objectID)
        }
        
        if _record == nil {
            // use perform insert object into context
            // but delay the object saving
            _record = await managedObjectContext.perform {
                guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else {
                    assertionFailure("invalid authentication record")
                    return nil
                }
                
                let now = Date()
                let obejct = MastodonNotificationSubscription.insert(
                    into: managedObjectContext,
                    property: .init(
                        id: nil,
                        domain: authenticationContext.domain,
                        endpoint: nil,
                        serverKey: nil,
                        userToken: authenticationContext.authorization.accessToken,
                        isActive: true,
                        follow: true,
                        favourite: true,
                        reblog: true,
                        mention: true,
                        poll: true,
                        createdAt: now,
                        updatedAt: now,
                        mentionPreference: MastodonNotificationSubscription.MentionPreference()
                    ),
                    relationship: .init(authentication: authentication)
                )
                return .init(objectID: obejct.objectID)
            }
        }
        
        guard let record = _record else {
            assertionFailure()
            throw AppError.implicit(.internal(reason: "Cannot create Mastodon notification subscription"))
        }

        return record
    }

}
