//
//  SceneDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import os.log
import UIKit
import Combine
import Intents
import FPSIndicator
import CoreDataStack
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    let logger = Logger(subsystem: "SceneDelegate", category: "Scene")
    
    var disposeBag = Set<AnyCancellable>()

    var window: UIWindow?
    var coordinator: SceneCoordinator?

    #if DEBUG || PROFILE
    var fpsIndicator: FPSIndicator?
    #endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        #if DEBUG && !PROFILE
        guard !SceneDelegate.isXcodeUnitTest else {
            window.rootViewController = UIViewController()
            return
        }
        #endif
        
        // set tint color
        window.tintColor = ThemeService.shared.theme.value.accentColor
        
        ThemeService.shared.theme
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] theme in
                guard let self = self else { return }
                guard let window = self.window else { return }
                window.tintColor = theme.accentColor
                window.subviews.forEach { view in
                    view.removeFromSuperview()
                    window.addSubview(view)
                }
            }
            .store(in: &disposeBag)
        
        let sceneCoordinator = SceneCoordinator(scene: scene, sceneDelegate: self, context: AppContext.shared)
        self.coordinator = sceneCoordinator
        
        let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity
        if userActivity?.activityType == UserActivity.openNewWindowActivityType,
           let objectIDURI = userActivity?.userInfo?[UserActivity.sessionUserInfoAuthenticationIndexObjectIDKey] as? URL,
           let objectID = AppContext.shared.managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectIDURI)
        {
            sceneCoordinator.setup(authentication: ManagedObjectRecord(objectID: objectID))
        } else {
            sceneCoordinator.setup()
        }
        
        window.makeKeyAndVisible()

        #if DEBUG || PROFILE
        fpsIndicator = FPSIndicator(windowScene: windowScene)
        #endif
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let interaction = userActivity.interaction else {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): Can't continue unknown NSUserActivity type \(userActivity.activityType)")
            return
        }

        switch interaction.intent {
        case is SwitchAccountIntent:
            guard let intent = interaction.intent as? SwitchAccountIntent,
                  let account = intent.account,
                  let identifier = account.identifier.flatMap(UUID.init(uuidString:))
            else {
                assertionFailure()
                return
            }
            let managedObjectContext = AppContext.shared.managedObjectContext
            Task { @MainActor in
                let _authenticationIndexRecord: ManagedObjectRecord<AuthenticationIndex>? = await managedObjectContext.perform {
                    let request = AuthenticationIndex.sortedFetchRequest
                    request.predicate = AuthenticationIndex.predicate(identifier: identifier)
                    guard let authenticationIndex = try? managedObjectContext.fetch(request).first else { return nil }
                    return .init(objectID: authenticationIndex.objectID)
                }
                guard let authenticationIndexRecord = _authenticationIndexRecord else {
                    return
                }
                let isActive = try await AppContext.shared.authenticationService.activeAuthenticationIndex(record: authenticationIndexRecord)
                guard isActive else { return }
                self.coordinator?.setup()
            }
        default:
            assertionFailure()
            return
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

extension SceneDelegate {
    
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem
    ) async -> Bool {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(shortcutItem.type)")
        guard let coordinator = self.coordinator else { return false }
        
        func topMostViewController() -> UIViewController? {
            return coordinator.sceneDelegate.window?.rootViewController?.topMost
        }
        

        switch shortcutItem.type {
        case "com.twidere.TwidereX.compose":
            if let topMost = topMostViewController(), topMost.isModal {
                topMost.dismiss(animated: false)
            }
            let composeViewModel = ComposeViewModel(context: coordinator.context)
            assertionFailure("TODO: check authContext and handle alert")
//            let composeContentViewModel = ComposeContentViewModel(
//                context: .shared,
//                authContext: <#T##AuthContext#>,
//                kind: .post,
//                configurationContext: .init(
//                    apiService: coordinator.context.apiService,
//                    authenticationService: coordinator.context.authenticationService,
//                    mastodonEmojiService: coordinator.context.mastodonEmojiService,
//                    statusViewConfigureContext: .init(
//                        dateTimeProvider: DateTimeSwiftProvider(),
//                        twitterTextProvider: OfficialTwitterTextProvider(),
//                        authenticationContext: coordinator.context.authenticationService.$activeAuthenticationContext
//                    )
//                )
//            )
//            coordinator.present(
//                scene: .compose(
//                    viewModel: composeViewModel,
//                    contentViewModel: composeContentViewModel
//                ),
//                from: nil,
//                transition: .modal(animated: true)
//            )
            return true
        case "com.twidere.TwidereX.search":
            if let topMost = topMostViewController(), topMost.isModal {
                topMost.dismiss(animated: false)
            }
            coordinator.switchToTabBar(tab: .search)
            return true
        case NotificationService.unreadShortcutItemIdentifier:
            guard let accessToken = shortcutItem.userInfo?["accessToken"] as? String else {
                assertionFailure()
                return false
            }
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(userAccessToken: accessToken)
            request.fetchLimit = 1
            guard let authentication = try? coordinator.context.managedObjectContext.fetch(request).first else {
                assertionFailure()
                return false
            }
            
            let _isActive = try? await coordinator.context.authenticationService.activeAuthenticationIndex(record: authentication.authenticationIndex.asRecrod)
            guard _isActive == true else {
                return false
            }
            
            coordinator.switchToTabBar(tab: .notification)
            return true
        default:
            assertionFailure()
            return false
        }
    }
    
}

extension SceneDelegate {
    
    public class func openSceneSessionForAccount(
        _ record: ManagedObjectRecord<AuthenticationIndex>,
        fromRequestingScene requestingScene: UIWindowScene
    ) throws {
        let options = UIWindowScene.ActivationRequestOptions()
        options.preferredPresentationStyle = .prominent
        options.requestingScene = requestingScene
        
        if let activeSceneSession = Self.activeSceneSessionForAccount(record) {
            UIApplication.shared.requestSceneSessionActivation(
                activeSceneSession,     // reuse old one
                userActivity: nil,      // ignore for actived session
                options: options
            )
        } else {
            let userActivity = record.openNewWindowUserActivity
            UIApplication.shared.requestSceneSessionActivation(
                nil,                    // create new one
                userActivity: userActivity,
                options: options
            )
        }
    }
    
    class func activeSceneSessionForAccount(_ record: ManagedObjectRecord<AuthenticationIndex>) -> UISceneSession? {
        for openSession in UIApplication.shared.openSessions where openSession.configuration.delegateClass == SceneDelegate.self {
            guard let userInfo = openSession.userInfo,
                  let objectIDURI = userInfo[UserActivity.sessionUserInfoAuthenticationIndexObjectIDKey] as? URL,
                  objectIDURI == record.objectID.uriRepresentation()
            else { continue }
            return openSession
        }   // end for … in
        
        return nil
    }
}

struct UserActivity {
    static var openNewWindowActivityType: String { "com.twidere.TwidereX.openNewWindow" }
    
    static var sessionUserInfoAuthenticationIndexObjectIDKey: String { "authenticationIndex.objectID" }
}

extension ManagedObjectRecord where T: AuthenticationIndex {
    var openNewWindowUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: UserActivity.openNewWindowActivityType)
        userActivity.userInfo = [
            UserActivity.sessionUserInfoAuthenticationIndexObjectIDKey: objectID.uriRepresentation()
        ]
        userActivity.targetContentIdentifier = "\(UserActivity.openNewWindowActivityType)-\(objectID)"
        return userActivity
    }
}

#if DEBUG
extension SceneDelegate {
    static var isXcodeUnitTest: Bool {
        return ProcessInfo().environment["XCInjectBundleInto"] != nil
    }
}
#endif
