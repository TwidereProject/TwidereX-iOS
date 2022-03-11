//
//  SceneCoordinator.swift
//  TwidereX
//
//  Created by jk234ert on 8/6/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit
import SafariServices
import CoreDataStack
import TwidereUI
import TwidereComposeUI

final public class SceneCoordinator {
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private weak var context: AppContext!
    
    let id = UUID().uuidString
    
    init(scene: UIScene, sceneDelegate: SceneDelegate, context: AppContext) {
        self.scene = scene
        self.sceneDelegate = sceneDelegate
        self.context = context
        
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
        case alertController(animated: Bool, completion: (() -> Void)? = nil)
    }
    
    enum Scene {
        // Onboarding
        case welcome(viewModel: WelcomeViewModel)
        case twitterAuthenticationOption(viewModel: TwitterAuthenticationOptionViewModel)
        case twitterPinBasedAuthentication(viewModel: TwitterPinBasedAuthenticationViewModel)
        
        // Account
        case accountList(viewModel: AccountListViewModel)
        case profile(viewModel: ProfileViewModel)
        case friendshipList(viewModel: FriendshipListViewModel)
        
        // Timeline
        case federatedTimeline(viewModel: FederatedTimelineViewModel)
        case userLikeTimeline(viewModel: UserLikeTimelineViewModel)
        
        // List
        case compositeList(viewModel: CompositeListViewModel)
        case list(viewModel: ListViewModel)
        case listStatus(viewModel: ListStatusViewModel)
        case listUser(viewModel: ListUserViewModel)
        
        // Status
        case statusThread(viewModel: StatusThreadViewModel)
        case compose(viewModel: ComposeViewModel, contentViewModel: ComposeContentViewModel)
        
        // Hashtag
        case hashtagTimeline(viewModel: HashtagTimelineViewModel)
        
        // MediaPreview
        case mediaPreview(viewModel: MediaPreviewViewModel)

        // Sidebar
        case drawerSidebar(viewModel: DrawerSidebarViewModel)

        // Search
        case savedSearch(viewModel: SavedSearchViewModel)
        case trend(viewModel: TrendViewModel)
        case searchResult(viewModel: SearchResultViewModel)
        
        case setting
        case displayPreference
        case about
        
        #if DEBUG
        case developer
        case stubTimeline
        #endif
        
        case safari(url: URL)
        case activityViewController(activityViewController: UIActivityViewController, sourceView: UIView)
        case alertController(alertController: UIAlertController)
    }
}

extension SceneCoordinator {
    
    func setup() {
        let viewController = MainTabBarController(context: context, coordinator: self)
        sceneDelegate.window?.rootViewController = viewController
    }
    
    func setupWelcomeIfNeeds() {
        do {
            let request = AuthenticationIndex.sortedFetchRequest
            let count = try context.managedObjectContext.count(for: request)
            if count == 0 {
                DispatchQueue.main.async {
                    let configuration = WelcomeViewModel.Configuration(allowDismissModal: false)
                    let welcomeViewModel = WelcomeViewModel(context: self.context, configuration: configuration)
                    self.present(scene: .welcome(viewModel: welcomeViewModel), from: nil, transition: .modal(animated: false, completion: nil))
                }
            }
            
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    @discardableResult
    @MainActor
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
        
        // Fix SearchViewController + UISearchController cause viewController always show as modal issue
        if let searchController = presentingViewController.presentingViewController as? SearchViewController {
            presentingViewController = searchController
        }
        
        switch transition {
        case .show:
            if presentingViewController.navigationController == nil,
               !(presentingViewController is UINavigationController),
               let from = presentingViewController.presentingViewController
            {
                presentingViewController.dismiss(animated: true) {
                    self.present(scene: scene, from: from, transition: .show)
                }
            } else {
                presentingViewController.show(viewController, sender: sender)
            }
            
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
            
        case .alertController(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
        }
        
        return viewController
    }

}

private extension SceneCoordinator {
    
    func get(scene: Scene) -> UIViewController? {
        let viewController: UIViewController?
        switch scene {
        case .welcome(let viewModel):
            let _viewController = WelcomeViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .twitterAuthenticationOption(let viewModel):
            let _viewController = TwitterAuthenticationOptionViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .twitterPinBasedAuthentication(let viewModel):
            let _viewController = TwitterPinBasedAuthenticationViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .accountList(let viewModel):
            let _viewController = AccountListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .friendshipList(let viewModel):
            switch viewModel.kind {
            case .following:
                let _viewController = FollowingListViewController()
                _viewController.viewModel = viewModel
                viewController = _viewController
            case .follower:
                let _viewController = FollowerListViewController()
                _viewController.viewModel = viewModel
                viewController = _viewController
            }
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .federatedTimeline(let viewModel):
            let _viewController = FederatedTimelineViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .userLikeTimeline(let viewModel):
            let _viewController = UserLikeTimelineViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .compositeList(let viewModel):
            let _viewController = CompositeListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .list(let viewModel):
            let _viewController = ListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .listStatus(let viewModel):
            let _viewController = ListStatusViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .listUser(let viewModel):
            let _viewController = ListUserViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .statusThread(let viewModel):
            let _viewController = StatusThreadViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .hashtagTimeline(let viewModel):
            let _viewController = HashtagTimelineViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .compose(let viewModel, let contentViewModel):
            let _viewController = ComposeViewController()
            _viewController.viewModel = viewModel
            _viewController.composeContentViewModel = contentViewModel
            viewController = _viewController

//        case .searchDetail(let viewModel):
//            let _viewController = SearchDetailViewController()
//            _viewController.viewModel = viewModel
//            viewController = _viewController

        case .mediaPreview(let viewModel):
            let _viewController = MediaPreviewViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .drawerSidebar(let viewModel):
            let _viewController = DrawerSidebarViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .savedSearch(let viewModel):
            let _viewController = SavedSearchViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .trend(let viewModel):
            let _viewController = TrendViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchResult(let viewModel):
            let searchResultViewController = SearchResultViewController()
            searchResultViewController.context = context
            searchResultViewController.coordinator = self
            searchResultViewController.viewModel = viewModel
            let _viewController = SearchResultContainerViewController()
            _viewController.searchText = viewModel.searchText
            _viewController.searchResultViewModel = viewModel
            _viewController.searchResultViewController = searchResultViewController
            viewController = _viewController
        case .setting:
            viewController = SettingListViewController()
        case .displayPreference:
            viewController = DisplayPreferenceViewController()
        case .about:
            viewController = AboutViewController()
        #if DEBUG
        case .developer:
            viewController = DeveloperViewController()
        case .stubTimeline:
            viewController = StubTimelineViewController()
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
        case .alertController(let alertController):
            if let popoverPresentationController = alertController.popoverPresentationController {
                assert(popoverPresentationController.sourceView != nil || popoverPresentationController.sourceRect != .zero || popoverPresentationController.barButtonItem != nil)
            }
            viewController = alertController
        }
        
        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }
    
    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = context
        needs?.coordinator = self
    }
    
}
