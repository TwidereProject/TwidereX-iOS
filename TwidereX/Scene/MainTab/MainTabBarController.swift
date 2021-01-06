//
//  MainTabBarController.swift
//  TwidereX
//
//  Created by jk234ert on 8/10/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwitterAPI
import SafariServices
import SwiftMessages

class MainTabBarController: UITabBarController {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    
    let doubleTapGestureRecognizer = UITapGestureRecognizer.doubleTapGestureRecognizer
    
    enum Tab: Int, CaseIterable {
        case timeline
        case mention
        case search
        case me
        
        var title: String {
            switch self {
            case .timeline:     return L10n.Scene.Timeline.title
            case .mention:      return L10n.Scene.Mentions.title
            case .search:       return L10n.Scene.Search.title
            case .me:           return L10n.Scene.Profile.title
            }
        }
        
        var image: UIImage {
            switch self {
            case .timeline:     return Asset.ObjectTools.house.image.withRenderingMode(.alwaysTemplate)
            case .mention:      return Asset.Communication.ellipsesBubble.image.withRenderingMode(.alwaysTemplate)
            case .search:       return Asset.ObjectTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate)
            case .me:           return Asset.Human.person.image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        func viewController(context: AppContext, coordinator: SceneCoordinator) -> UIViewController {
            let viewController: UIViewController
            switch self {
            case .timeline:
                let _viewController = HomeTimelineViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .mention:
                let _viewController = MentionTimelineViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .search:
                let _viewController = SearchViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
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
            viewController.tabBarItem.title = "" // set text to empty string for image only style (SDK failed to layout when set to nil)
            viewController.tabBarItem.image = tab.image
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        // TODO: custom accent color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBar.standardAppearance = tabBarAppearance
        
        context.apiService.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let _ = self else { return }
                switch error {
                case .implicit:
                    break
                case .explicit(let reason):
                    let messageConfig = reason.messageConfig
                    let notifyBannerView = reason.notifyBannerView
                    SwiftMessages.show(config: messageConfig, view: notifyBannerView)
                }
            }
            .store(in: &disposeBag)
        
        doubleTapGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.doubleTapGestureRecognizerHandler(_:)))
        doubleTapGestureRecognizer.delaysTouchesEnded = false
        tabBar.addGestureRecognizer(doubleTapGestureRecognizer)
        
        delegate = self
        
        #if DEBUG
        // selectedIndex = 1
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if DEBUG
        //coordinator.present(scene: .displayPreference, from: nil, transition: .show)
        #endif
    }
        
}

extension MainTabBarController {
    @objc private func doubleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        switch sender.state {
        case .ended:
            guard let scrollViewContainer = selectedViewController?.topMost as? ScrollViewContainer else { return }
            scrollViewContainer.scrollToTop(animated: true)
        default:
            break
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: didSelect item: %s", ((#file as NSString).lastPathComponent), #line, #function, item.debugDescription)
    }
}
