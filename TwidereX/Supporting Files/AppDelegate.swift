//
//  AppDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import AVKit
import UIKit
import Combine
import Floaty
import Firebase
import Kingfisher
import AppShared
import TwidereCommon

@_exported import TwidereUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var disposeBag = Set<AnyCancellable>()

    let appContext = AppContext(appSecret: .default)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
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
        
        // configure alternative app icon
        UserDefaults.shared.publisher(for: \.alternateIconNamePreference)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { preference in
                UIApplication.shared.setAlternateIconName(preference == .twidere ? nil : preference.iconName)
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
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .portrait
        default:
            return .all
        }
    }
}

extension AppContext {
    static var shared: AppContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.appContext
    }
}
