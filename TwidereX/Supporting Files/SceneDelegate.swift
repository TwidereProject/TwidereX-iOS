//
//  SceneDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import UIKit
import CoreDataStack

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: SceneCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // #if DEBUG
        // let window = TestWindow(windowScene: windowScene)
        // #endif

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        #if DEBUG
        guard !SceneDelegate.isXcodeUnitTest else {
            window.rootViewController = UIViewController()
            return
        }
        #endif
        
        let appContext = AppContext.shared
        let sceneCoordinator = SceneCoordinator(scene: scene, sceneDelegate: self, appContext: appContext)
        self.coordinator = sceneCoordinator
        
        sceneCoordinator.setup()
        
        do {
            let request = AuthenticationIndex.sortedFetchRequest
            if try appContext.managedObjectContext.fetch(request).isEmpty {
                DispatchQueue.main.async {
                    let authenticationViewModel = AuthenticationViewModel(isCloseBarButtonItemHidden: true)
                    sceneCoordinator.present(scene: .authentication(viewModel: authenticationViewModel), from: nil, transition: .modal(animated: false, completion: nil))
                }
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        window.makeKeyAndVisible()
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

#if DEBUG
class TestWindow: UIWindow {
    override func sendEvent(_ event: UIEvent) {
        event.allTouches?.forEach({ (touch) in
            let location = touch.location(in: self)
            if let view = hitTest(location, with: event) {
                print(view)
            }
        })
        
        super.sendEvent(event)
    }
}
#endif
