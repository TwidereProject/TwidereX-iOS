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
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    let appSecret: AppSecret
    
    var isNotificationPermissionGranted = false
    var fcmToken: String? {
        didSet {
            notifySubscribers()
        }
    }
        
    // output
    var subscribers: [NotificationSubscriber] = [] {
        didSet {
            notifySubscribers()
        }
    }
//    let applicationIconBadgeNeedsUpdate = CurrentValueSubject<Void, Never>(Void())
//    let unreadNotificationCountDidUpdate = CurrentValueSubject<Void, Never>(Void())
//    let requestRevealNotificationPublisher = PassthroughSubject<MastodonPushNotification, Never>()
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService,
        appSecret: AppSecret
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        self.appSecret = appSecret
        
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
        
//        Publishers.CombineLatest(
//            authenticationService.mastodonAuthentications,
//            applicationIconBadgeNeedsUpdate
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] mastodonAuthentications, _ in
//            guard let self = self else { return }
//
//            var count = 0
//            for authentication in mastodonAuthentications {
//                count += UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authentication.userAccessToken)
//            }
//
//            UserDefaults.shared.notificationBadgeCount = count
//            UIApplication.shared.applicationIconBadgeNumber = count
//
//            self.unreadNotificationCountDidUpdate.send()
//        }
//        .store(in: &disposeBag)
    }
    
}

extension NotificationService {
    public func updateToken(_ token: String?) {
        fcmToken = token
    }
}

extension NotificationService {
    private func notifySubscribers() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let api = self.apiService else {
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
}

extension NotificationService {
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
