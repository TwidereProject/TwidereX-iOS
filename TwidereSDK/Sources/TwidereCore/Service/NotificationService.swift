//
//  NotificationService.swift
//  
//
//  Created by MainasuK on 2022-7-6.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwidereCommon

final public actor NotificationService {
    
    let logger = Logger(subsystem: "NotificationService", category: "NotificationService")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    weak var api: APIService?
    weak var authenticationService: AuthenticationService?
    let appSecret: AppSecret
    
    var isNotificationPermissionGranted = false
    var fcmToken: String? {
        didSet {
            notifySubscribers()
        }
    }
        
    // output
    public private(set) var subscribers: [NotificationSubscriber] = [] {
        didSet {
            notifySubscribers()
        }
    }
    public let applicationIconBadgeNeedsUpdate = CurrentValueSubject<Void, Never>(Void())
    public let unreadNotificationCountDidUpdate = CurrentValueSubject<Void, Never>(Void())
    public let requestRevealNotificationPublisher = PassthroughSubject<MastodonPushNotification, Never>()
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService,
        appSecret: AppSecret
    ) {
        self.api = apiService
        self.authenticationService = authenticationService
        self.appSecret = appSecret
        
        // request notification permission if needs
        // register notification subscriber
        authenticationService.$authenticationIndexes
            .sink { [weak self] authenticationIndexes in
                guard let self = self else { return }
                
                // request permission when sign-in account
                Task {
                    if !authenticationIndexes.isEmpty {
                        await self.requestNotificationPermission()
                    }
                }   // end Task
                
                Task {
                    let authenticationContexts = authenticationIndexes.compactMap { authenticationIndex in
                        AuthenticationContext(authenticationIndex: authenticationIndex, secret: self.appSecret.secret)
                    }
                    await self.updateSubscribers(authenticationContexts)
                }   // end Task
            }
            .store(in: &disposeBag)         // FIXME: how to use disposeBag in actor under Swift 6 ??
        
        Publishers.CombineLatest(
            authenticationService.$authenticationIndexes,
            applicationIconBadgeNeedsUpdate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authenticationIndexes, _ in
            guard let self = self else { return }

            let authenticationContexts = authenticationIndexes.compactMap { authenticationIndex in
                AuthenticationContext(authenticationIndex: authenticationIndex, secret: self.appSecret.secret)
            }
            
            var count = 0
            for authenticationContext in authenticationContexts {
                switch authenticationContext {
                case .twitter:
                    continue
                case .mastodon(let authenticationContext):
                    let accessToken = authenticationContext.authorization.accessToken
                    let _count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                    count += _count
                }
            }

            UserDefaults.shared.notificationBadgeCount = count
            let _count = count
            Task {
                await self.updateApplicationIconBadge(count: _count)
            }
            self.unreadNotificationCountDidUpdate.send()
        }
        .store(in: &disposeBag)
    }
    
}

extension NotificationService {
    
    public func clearNotificationCountForActiveUser() {
        guard let authenticationService = self.authenticationService else { return }
        guard let authenticationContext = authenticationService.activeAuthenticationContext else { return }
        switch authenticationContext {
        case .twitter:
            return
        case .mastodon(let authenticationContext):
            let accessToken = authenticationContext.authorization.accessToken
            UserDefaults.shared.setNotificationCountWithAccessToken(accessToken: accessToken, value: 0)
        }
        
        applicationIconBadgeNeedsUpdate.send()
    }
    
    public func updateToken(_ token: String?) {
        fcmToken = token
    }
    
    public func notifySubscriber(authenticationContext: AuthenticationContext) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public). authenticationContext: \(String(describing: authenticationContext))")

        guard let api = self.api else { return }
        guard let subscriber = dequeueSubscriber(authenticationContext: authenticationContext) else { return }
        let subject = NotificationSubject(
            fcmToken: fcmToken,
            appSecret: appSecret
        )
        subscriber.update(api: api, subject: subject)
    }
    
    public func receive(pushNotification: MastodonPushNotification) async {
        defer {
            unreadNotificationCountDidUpdate.send()
        }
        
        try? await fetchLatestNotifications(pushNotification: pushNotification)
        try? await cancelSubscriptionForDetachedAccount(pushNotification: pushNotification)
    }
    
}

extension NotificationService {
    
    @MainActor
    private func updateApplicationIconBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    private func requestNotificationPermission() async {
        do {
            let center = UNUserNotificationCenter.current()
            let isGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): request push notification permission: isGranted -> \(isGranted)")

            isNotificationPermissionGranted = isGranted
            
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): request push notification permission fail: \(error.localizedDescription)")
        }
    }
    
}

extension NotificationService {
    
    private func notifySubscribers() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let api = self.api else {
            assertionFailure()
            return
        }
        
        let subject = NotificationSubject(
            fcmToken: fcmToken,
            appSecret: appSecret
        )
        
        for subscriber in subscribers {
            subscriber.update(api: api, subject: subject)
        }
    }
    
    private func updateSubscribers(_ authenticationContexts: [AuthenticationContext]) async {
        subscribers = authenticationContexts.compactMap {
            return dequeueSubscriber(authenticationContext: $0)
        }
    }   // end func
    
    private func dequeueSubscriber(
        authenticationContext: AuthenticationContext
    ) -> NotificationSubscriber? {
        let userIdentifier = authenticationContext.userIdentifier
        if let subscriber = subscribers.first(where: { $0.userIdentifier == userIdentifier }) {
            return subscriber
        } else {
            switch authenticationContext {
            case .twitter:
                return nil
            case .mastodon(let authenticationContext):
                return MastodonNotificationSubscriber(authenticationContext: authenticationContext)
            }   // end switch
        }
    }   // end func
}


extension NotificationService {
    
    private func fetchLatestNotifications(
        pushNotification: MastodonPushNotification
    ) async throws {
        guard let api = self.api else { return }
        guard let authenticationContext = try await authenticationContext(for: pushNotification) else { return }
        
        _ = try await api.mastodonNotificationTimeline(
            query: .init(),
            scope: .all,
            authenticationContext: authenticationContext
        )
    }
    
    private func authenticationContext(for pushNotification: MastodonPushNotification) async throws -> MastodonAuthenticationContext? {
        guard let authenticationService = self.authenticationService else { return nil }
        let managedObjectContext = authenticationService.managedObjectContext
        let _authenticationContext: MastodonAuthenticationContext? = await managedObjectContext.perform {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(userAccessToken: pushNotification.accessToken)
            request.fetchLimit = 1
            guard let authentication = try? managedObjectContext.fetch(request).first else { return nil }
            return MastodonAuthenticationContext(authentication: authentication)
        }
        return _authenticationContext
    }
    
    private func cancelSubscriptionForDetachedAccount(
        pushNotification: MastodonPushNotification
    ) async throws {
        // Subscription maybe failed to cancel when sign-out
        // Try cancel again if receive that kind push notification
        guard let api = self.api else { return }
        guard let managedObjectContext = authenticationService?.managedObjectContext else { return }

        let userAccessToken = pushNotification.accessToken

        let needsCancelSubscription: Bool = try await managedObjectContext.perform {
            // check authentication exists
            let authenticationRequest = MastodonAuthentication.sortedFetchRequest
            authenticationRequest.predicate = MastodonAuthentication.predicate(userAccessToken: userAccessToken)
            return try managedObjectContext.fetch(authenticationRequest).first == nil
        }
        
        guard needsCancelSubscription else { return }
        guard let domain = try await domain(for: pushNotification) else { return }
        
        do {
            _ = try await api.cancelMastodonNotificationSubscription(
                domain: domain,
                authorization: .init(accessToken: userAccessToken)
            )
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] cancel sign-out user subscription", ((#file as NSString).lastPathComponent), #line, #function)
        } catch {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] failed to cancel sign-out user subscription: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
    
    private func domain(for pushNotification: MastodonPushNotification) async throws -> String? {
        guard let authenticationService = self.authenticationService else { return nil }
        let managedObjectContext = authenticationService.managedObjectContext
        return try await managedObjectContext.perform {
            let subscriptionRequest = MastodonNotificationSubscription.sortedFetchRequest
            subscriptionRequest.predicate = MastodonNotificationSubscription.predicate(userToken: pushNotification.accessToken)
            let subscriptions = try managedObjectContext.fetch(subscriptionRequest)
            guard let subscription = subscriptions.first else { return nil }
            let domain = subscription.domain
            return domain
        }
    }
    
}
