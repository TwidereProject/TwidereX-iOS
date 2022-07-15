//
//  AppDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import os.log
import AVKit
import UIKit
import Combine
import Floaty
import Firebase
import FirebaseMessaging
import Kingfisher
import AppShared
import TwidereCommon

@_exported import TwidereUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let logger = Logger(subsystem: "AppDelegate", category: "AppDelegate")

    var disposeBag = Set<AnyCancellable>()

    let appContext = AppContext(appSecret: .default)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppSecret.register()
        
        // setup push notification
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // Firebase
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCustomValue(Locale.preferredLanguages.first ?? "nil", forKey: "preferredLanguage")
        Messaging.messaging().delegate = self
        
        // configure AudioSession
        try? AVAudioSession.sharedInstance().setCategory(.ambient)

        // Update app version info. See: `Settings.bundle`
        UserDefaults.standard.setValue(UIApplication.appVersion(), forKey: "TwidereX.appVersion")
        UserDefaults.standard.setValue(UIApplication.appBuild(), forKey: "TwidereX.appBundle")

        // Setup Kingfisher cache
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024   // 50MB
        ImageCache.default.memoryStorage.config.expiration = .seconds(600)
        ImageCache.default.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .days(7)
        
        // enable FAB RTL support
        Floaty.global.rtlMode = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        
        // configure appearance
        ThemeService.shared.apply(theme: ThemeService.shared.theme.value)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        #if DEBUG
        return .all
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .portrait
        default:
            return .all
        }
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // notification present in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push]", ((#file as NSString).lastPathComponent), #line, #function)
        guard let pushNotification = AppDelegate.mastodonPushNotification(from: notification) else {
            completionHandler([])
            return
        }
        
        let notificationID = String(pushNotification.notificationID)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push] notification %s", ((#file as NSString).lastPathComponent), #line, #function, notificationID)
        
        let accessToken = pushNotification.accessToken
        UserDefaults.shared.increaseNotificationCount(accessToken: accessToken)
        Task {
            await self.appContext.notificationService.applicationIconBadgeNeedsUpdate.send()
            await self.appContext.notificationService.receive(pushNotification: pushNotification)
        }   // end Task
        
        completionHandler([.sound])
    }
    
    private static func mastodonPushNotification(from notification: UNNotification) -> MastodonPushNotification? {
        guard let plaintext = notification.request.content.userInfo["plaintext"] as? Data,
              let mastodonPushNotification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintext) else {
            return nil
        }
        
        return mastodonPushNotification
    }
    
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fcmToken: \(fcmToken ?? "<nil>")")
        
        Task {
            await appContext.notificationService.updateToken(fcmToken)
        }   // end Task
    }
}

extension AppContext {
    static var shared: AppContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.appContext
    }
}
