//
//  SceneCoordinator.swift
//  TwidereX
//
//  Created by jk234ert on 8/6/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit
import SafariServices

final public class SceneCoordinator {
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private weak var appContext: AppContext!
    
    let id = UUID().uuidString
    
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
        case safariPresent(animated: Bool, completion: (() -> Void)? = nil)
        case activityViewControllerPresent(animated: Bool, completion: (() -> Void)? = nil)
    }
    
    enum Scene {
        case authentication
        case twitterPinBasedAuthentication(viewModel: TwitterPinBasedAuthenticationViewModel)
        case accountList(viewModel: AccountListViewModel)
        case composeTweet(viewModel: ComposeTweetViewModel)
        case mentionPick(viewModel: MentionPickViewModel, delegate: MentionPickViewControllerDelegate)
        case tweetConversation(viewModel: TweetConversationViewModel)
        case searchDetail(viewModel: SearchDetailViewModel)
        case profile(viewModel: ProfileViewModel)
        case friendshipList(viewModel: FriendshipListViewModel)
        case mediaPreview(viewModel: MediaPreviewViewModel)
        case drawerSidebar
        
        case setting
        case displayPreference
        case about
        
        #if DEBUG
        case developer
        #endif
        
        case safari(url: URL)
        case activityViewController(activityViewController: UIActivityViewController, sourceView: UIView)
    }
}

extension SceneCoordinator {
    
    func setup() {
        let viewController = MainTabBarController(context: appContext, coordinator: self)
        sceneDelegate.window?.rootViewController = viewController
    }
    
    @discardableResult
    func present(scene: Scene, from sender: UIViewController?, transition: Transition) -> UIViewController? {
        guard let viewController = get(scene: scene) else {
            return nil
        }
        guard var presentingViewController = sender ?? sceneDelegate.window?.rootViewController?.topMost else {
            return nil
        }
        
        if let mainTabBarController = presentingViewController as? MainTabBarController,
           let navigationController = mainTabBarController.selectedViewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            presentingViewController = topViewController
        }
        
        switch transition {
        case .show:
            presentingViewController.show(viewController, sender: sender)
            
        case .showDetail:
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
            assert(sender?.navigationController?.delegate != nil)
            sender?.navigationController?.pushViewController(viewController, animated: true)
            
        case .safariPresent(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
        case .activityViewControllerPresent(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
        }
        
        return viewController
    }

}

private extension SceneCoordinator {
    
    func get(scene: Scene) -> UIViewController? {
        let viewController: UIViewController?
        switch scene {
        case .authentication:
            viewController = AuthenticationViewController()
        case .twitterPinBasedAuthentication(let viewModel):
            let _viewController = TwitterPinBasedAuthenticationViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .accountList(let viewModel):
            let _viewController = AccountListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .composeTweet(let viewModel):
            let _viewController = ComposeTweetViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mentionPick(let viewModel, let delegate):
            let _viewController = MentionPickViewController()
            _viewController.viewModel = viewModel
            _viewController.delegate = delegate
            viewController = _viewController
        case .tweetConversation(let viewModel):
            let _viewController = TweetConversationViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchDetail(let viewModel):
            let _viewController = SearchDetailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .friendshipList(let viewModel):
            switch viewModel.friendshipLookupKind {
            case .following:
                let _viewController = FollowingListViewController()
                _viewController.viewModel = viewModel
                viewController = _viewController
            case .followers:
                let _viewController = FollowerListViewController()
                _viewController.viewModel = viewModel
                viewController = _viewController
            }
        case .mediaPreview(let viewModel):
            let _viewController = MediaPreviewViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .drawerSidebar:
            viewController = DrawerSidebarViewController()
        case .setting:
            viewController = SettingListViewController()
        case .displayPreference:
            viewController = DisplayPreferenceViewController()
        case .about:
            viewController = AboutViewController()
        #if DEBUG
        case .developer:
            viewController = DeveloperViewController()
        #endif
        case .safari(let url):
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                return nil
            }
            viewController = SFSafariViewController(url: url)
        case .activityViewController(let activityViewController, let sourceView):
            activityViewController.popoverPresentationController?.sourceView = sourceView
            viewController = activityViewController
        }
        
        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }
    
    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = appContext
        needs?.coordinator = self
    }
    
}
