//
//  AppDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import UIKit
import Combine
import Firebase
import Kingfisher
//import Floaty

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var disposeBag = Set<AnyCancellable>()

    let appContext = AppContext()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if !DEBUG
        FirebaseApp.configure()
        #endif
        
        // Update app version info. See: `Settings.bundle`
        UserDefaults.standard.setValue(UIApplication.appVersion(), forKey: "TwidereX.appVersion")
        UserDefaults.standard.setValue(UIApplication.appBuild(), forKey: "TwidereX.appBundle")

        // Setup Kingfisher cache
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024   // 50MB
        ImageCache.default.memoryStorage.config.expiration = .seconds(600)
        ImageCache.default.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .days(7)
        
//        Floaty.global.rtlMode = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { _ in
                // only trigger update
                UserDefaults.shared.useTheSystemFontSize = UserDefaults.shared.useTheSystemFontSize
            }
            .store(in: &disposeBag)

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
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
        #endif
    }
}


extension AppContext {
    static var shared: AppContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.appContext
    }
}
