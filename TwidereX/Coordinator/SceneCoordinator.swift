//
//  SceneCoordinator.swift
//  TwidereX
//
//  Created by jk234ert on 8/6/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

final public class SceneCoordinator {
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private weak var appContext: AppContext!
    
    let id = UUID().uuidString
    private var secondaryStackHashValues = Set<Int>()
    
    var mainTabViewController: MainTabBarController!
    
    init(scene: UIScene, sceneDelegate: SceneDelegate, appContext: AppContext) {
        self.scene = scene
        self.sceneDelegate = sceneDelegate
        self.appContext = appContext
        
        scene.session.sceneCoordinator = self
    }
}

extension SceneCoordinator {
    enum Transition {
        case show                           // push
        case showDetail                     // replace
        case modal(animated: Bool, completion: (() -> Void)? = nil)
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush
    }
    
    enum Scene {
        case authentication
        case composeTweet(viewModel: ComposeTweetViewModel)
        case tweetConversation(viewModel: TweetConversationViewModel)
        case profile(viewModel: ProfileViewModel)
    }
}

extension SceneCoordinator {
    
    func setup() {
        let _mainTabViewController = MainTabBarController(context: appContext, coordinator: self)
        mainTabViewController = _mainTabViewController
        
        if #available(iOS 14.0, *) {
            
            if sceneDelegate.window?.traitCollection.userInterfaceIdiom == .pad || sceneDelegate.window?.traitCollection.userInterfaceIdiom == .mac {
                let sidebarViewController = SidebarViewController()
                let splitViewController = UISplitViewController(style: .doubleColumn)
                splitViewController.primaryBackgroundStyle = .sidebar
                splitViewController.preferredDisplayMode = .automatic
                splitViewController.setViewController(sidebarViewController, for: .primary)
                splitViewController.setViewController(_mainTabViewController, for: .secondary)
                _mainTabViewController.tabBar.isHidden = true
                sceneDelegate.window?.rootViewController = splitViewController
                
                #if targetEnvironment(macCatalyst)
                guard let windowScene = scene as? UIWindowScene else { return }
                let toolbar = NSToolbar(identifier: "main")
                // toolbar.delegate = toolbarDelegate
                toolbar.displayMode = .iconOnly
                if let titlebar = windowScene.titlebar {
                    titlebar.toolbar = toolbar
                    titlebar.toolbarStyle = .automatic
                }
                #endif
                
            } else {
                sceneDelegate.window?.rootViewController = _mainTabViewController
            }
        } else {
            sceneDelegate.window?.rootViewController = _mainTabViewController
        }
        
//        let viewController = RootSplitViewController()
//        setupDependency(for: viewController)
//        viewController.delegate = self
//        sceneDelegate.window?.rootViewController = viewController
    }
    
    @discardableResult
    func present(scene: Scene, from sender: UIViewController?, transition: Transition) -> UIViewController? {
        let viewController = get(scene: scene)
        guard let presentingViewController = sender ?? sceneDelegate.window?.rootViewController else {
            return nil
        }
        
        switch transition {
        case .show:
            if secondaryStackHashValues.contains(presentingViewController.hashValue) {
                secondaryStackHashValues.insert(viewController.hashValue)
            }
            presentingViewController.show(viewController, sender: sender)
            
        case .showDetail:
            secondaryStackHashValues.insert(viewController.hashValue)
            let navigationController = UINavigationController(rootViewController: viewController)
            presentingViewController.showDetailViewController(navigationController, sender: sender)
            
        case .modal(let animated, let completion):
            let modalNavigationController = UINavigationController(rootViewController: viewController)
            if let adaptivePresentationControllerDelegate = viewController as? UIAdaptivePresentationControllerDelegate {
                modalNavigationController.presentationController?.delegate = adaptivePresentationControllerDelegate
            }
            presentingViewController.present(modalNavigationController, animated: animated, completion: completion)
        case .custom(let transitioningDelegate):
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = transitioningDelegate
            sender?.present(viewController, animated: true, completion: nil)
            
        case .customPush:
            // set delegate in view controller
            sender?.navigationController?.pushViewController(viewController, animated: true)
        }
        
        return viewController
    }
    
    
}

private extension SceneCoordinator {
    
    func get(scene: Scene) -> UIViewController {
        let viewController: UIViewController
        switch scene {
        case .authentication:
            viewController = AuthenticationViewController()
        case .composeTweet(let viewModel):
            let _viewController = ComposeTweetViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .tweetConversation(let viewModel):
            let _viewController = TweetConversationViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        }
        
        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }
    
    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = appContext
        needs?.coordinator = self
    }
    
}

// MARK: - UISplitViewControllerDelegate
//extension SceneCoordinator: UISplitViewControllerDelegate {
//    
//    public func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
//        if splitViewController.isCollapsed {
//            let selectedNavigationController = ((splitViewController.viewControllers.first as? UITabBarController)?.selectedViewController as? UINavigationController)
//            if let navigationController = vc as? UINavigationController, let topViewController = navigationController.topViewController {
//                selectedNavigationController?.pushViewController(topViewController, animated: true)
//            } else {
//                selectedNavigationController?.pushViewController(vc, animated: true)
//            }
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    public func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
//        guard let primaeryTabBarController = primaryViewController as? UITabBarController,
//            let selectedNavigationController = primaeryTabBarController.selectedViewController as? UINavigationController else {
//                return false
//        }
//        
//        guard let secondaryNavigationController = secondaryViewController as? UINavigationController else {
//            return false
//        }
//        
//        guard !(secondaryNavigationController.topViewController is PlaceholderDetailViewController) else {
//            // discard collapse operation
//            return true
//        }
//        
//        let secondaryNavigationStack = secondaryNavigationController.viewControllers
//        let collapsedNavigationStack = [selectedNavigationController.viewControllers, secondaryNavigationStack].flatMap { $0 }
//        selectedNavigationController.setViewControllers(collapsedNavigationStack, animated: false)
//        
//        return true
//    }
//    
//    public func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
//        guard let primaeryTabBarController = primaryViewController as? UITabBarController,
//            let selectedNavigationController = primaeryTabBarController.selectedViewController as? UINavigationController else {
//                return nil
//        }
//        
//        var primaryViewControllerStack: [UIViewController] = []
//        var secondaryViewControllerStack: [UIViewController] = []
//        for viewController in selectedNavigationController.viewControllers {
//            if secondaryStackHashValues.contains(viewController.hashValue) {
//                secondaryViewControllerStack.append(viewController)
//            } else {
//                primaryViewControllerStack.append(viewController)
//            }
//        }
//        
//        selectedNavigationController.setViewControllers(primaryViewControllerStack, animated: false)
//        
//        let secondaryNavigationController = UINavigationController()
//        if secondaryViewControllerStack.isEmpty {
//            secondaryNavigationController.setViewControllers([PlaceholderDetailViewController()], animated: false)
//        } else {
//            secondaryNavigationController.setViewControllers(secondaryViewControllerStack, animated: false)
//        }
//        
//        return secondaryNavigationController
//    }
//    
//}
