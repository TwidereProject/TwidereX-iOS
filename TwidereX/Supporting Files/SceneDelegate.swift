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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    let logger = Logger(subsystem: "SceneDelegate", category: "Scene")
    
    var disposeBag = Set<AnyCancellable>()

    var window: UIWindow?
    var coordinator: SceneCoordinator?

    #if DEBUG
    var fpsIndicator: FPSIndicator?
    #endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        #if DEBUG
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
        
        sceneCoordinator.setup()
        sceneCoordinator.setupWelcomeIfNeeds()
        
        window.makeKeyAndVisible()

        #if DEBUG
        // fpsIndicator = FPSIndicator(windowScene: windowScene)
        #endif
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let interaction = userActivity.interaction else {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): Can't continue unknown NSUserActivity type \(userActivity.activityType)")
            return
        }

        print(interaction)
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

#if DEBUG
extension SceneDelegate {
    static var isXcodeUnitTest: Bool {
        return ProcessInfo().environment["XCInjectBundleInto"] != nil
    }
}
#endif
