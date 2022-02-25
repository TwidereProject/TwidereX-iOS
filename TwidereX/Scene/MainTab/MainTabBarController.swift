//
//  MainTabBarController.swift
//  TwidereX
//
//  Created by jk234ert on 8/10/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import SafariServices
import SwiftMessages
import TwitterSDK
import TwidereUI

class MainTabBarController: UITabBarController {
    
    let logger = Logger(subsystem: "MainTabBarController", category: "TabBar")
    
    var disposeBag = Set<AnyCancellable>()
        
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!

    @Published var currentTab: Tab = .home
    
    enum Tab: Int, CaseIterable {
        case home
        case notification
        case search
        case me
        
        var title: String {
            switch self {
            case .home:         return L10n.Scene.Timeline.title
            case .notification: return L10n.Scene.Notification.title
            case .search:       return L10n.Scene.Search.title
            case .me:           return L10n.Scene.Profile.title
            }
        }
        
        var image: UIImage {
            switch self {
            case .home:             return Asset.ObjectTools.house.image.withRenderingMode(.alwaysTemplate)
            case .notification:     return Asset.ObjectTools.bell.image.withRenderingMode(.alwaysTemplate)
            case .search:           return Asset.ObjectTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate)
            case .me:               return Asset.Human.person.image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        var largeImage: UIImage {
            switch self {
            case .home:             return Asset.ObjectTools.houseLarge.image.withRenderingMode(.alwaysTemplate)
            case .notification:     return Asset.ObjectTools.bellLarge.image.withRenderingMode(.alwaysTemplate)
            case .search:           return Asset.ObjectTools.magnifyingglassLarge.image.withRenderingMode(.alwaysTemplate)
            case .me:               return Asset.Human.personLarge.image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        func viewController(context: AppContext, coordinator: SceneCoordinator) -> UIViewController {
            let viewController: UIViewController
            switch self {
            case .home:
                let _viewController = HomeTimelineViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                _viewController.viewModel = HomeTimelineViewModel(context: context)
                _viewController.viewModel.needsSetupAvatarBarButtonItem = true
                viewController = _viewController
            case .notification:
                let _viewController = NotificationViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .search:
                let _viewController = SearchViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                _viewController.viewModel = SearchViewModel(context: context)
                viewController = _viewController
            case .me:
                let _viewController = ProfileViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                let profileViewModel = MeProfileViewModel(context: context)
                _viewController.viewModel = profileViewModel
                viewController = _viewController
            }
            viewController.title = self.title
            return UINavigationController(rootViewController: viewController)
        }
    }
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension MainTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let tabs = Tab.allCases
        let viewControllers: [UIViewController] = tabs.map { tab in
            let viewController = tab.viewController(context: context, coordinator: coordinator)
            viewController.tabBarItem.title = tab.title
            viewController.tabBarItem.image = tab.image
            viewController.tabBarItem.accessibilityLabel = tab.title
            viewController.tabBarItem.largeContentSizeImage = tab.largeImage
            
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        let feedbackGenerator = UINotificationFeedbackGenerator()

        context.publisherService.statusPublishResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let _ = self else { return }
                switch result {
                case .success(let result):
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    let bannerView = NotificationBannerView()
                    bannerView.configure(style: .success)
                    switch result {
                    case .twitter:
                        bannerView.titleLabel.text = L10n.Common.Alerts.TweetPosted.title
                        bannerView.messageLabel.isHidden = true
                    case .mastodon:
                        bannerView.titleLabel.text = L10n.Common.Alerts.TootPosted.title
                        bannerView.messageLabel.isHidden = true
                    }
                    
                    feedbackGenerator.prepare()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        SwiftMessages.show(config: config, view: bannerView)
                        feedbackGenerator.notificationOccurred(.success)
                    }
                case .failure(let error):
                    guard let error = error as? LocalizedError else {
                        return
                    }
                    
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    
                    let bannerView = NotificationBannerView()
                    bannerView.configure(style: .error)
                    bannerView.configure(error: error)
                    
                    feedbackGenerator.prepare()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        SwiftMessages.show(config: config, view: bannerView)
                        feedbackGenerator.notificationOccurred(.error)
                    }
                }
            }
            .store(in: &disposeBag)
        
        delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if DEBUG
        //coordinator.present(scene: .displayPreference, from: nil, transition: .show)
        #endif
    }
        
}

//extension MainTabBarController {
//    @objc private func doubleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        switch sender.state {
//        case .ended:
//            guard let scrollViewContainer = selectedViewController?.topMost as? ScrollViewContainer else { return }
//            scrollViewContainer.scrollToTop(animated: true)
//        default:
//            break
//        }
//    }
//}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        defer {
            if let tab = Tab(rawValue: tabBarController.selectedIndex) {
                currentTab = tab
            }
        }
        
        guard currentTab.rawValue == tabBarController.selectedIndex,
              let navigationController = viewController as? UINavigationController,
              navigationController.viewControllers.count == 1
        else { return }
        
        let _scrollViewContainer = (navigationController.topViewController as? ScrollViewContainer) ?? (navigationController.topMost as? ScrollViewContainer)
        guard let scrollViewContainer = _scrollViewContainer else {
            return
        }
        scrollViewContainer.scrollToTop(animated: true)
    }
}
