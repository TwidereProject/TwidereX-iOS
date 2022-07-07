//
//  NotificationService+NotificationViewModel.swift
//  
//
//  Created by MainasuK on 2022-7-6.
//

import os.log
import Foundation
import Combine
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

        // output
        
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
        guard let token = subject.fcmToken else {
            throw AppError.implicit(.badRequest)
        }

        let appSecret = subject.appSecret
        let endpoint = appSecret.mastodonNotificationRelayEndpoint + "/" + token
        let p256dh = appSecret.mastodonNotificationPublicKey.x963Representation
        let auth = appSecret.mastodonNotificationAuth
        
        try await api.createMastodonNotificationSubscription(
            query: .init(
                subscription: .init(
                    endpoint: endpoint,
                    keys: .init(
                        p256dh: p256dh,
                        auth: auth
                    )
                ),
                data: .init(alerts: .init(
                    favourite: true,
                    follow: true,
                    reblog: true,
                    mention: true,
                    poll: true
                ))
            ),
            authenticationContext: authenticationContext
        )
    }

}
