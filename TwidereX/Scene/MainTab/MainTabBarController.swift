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
    
    enum Tab: Int, CaseIterable {
        case timeline
        case mention
        case search
        case me
        
        var title: String {
            switch self {
            case .timeline:     return "Timeline"
            case .mention:      return "Mention"
            case .search:       return "Search"
            case .me:           return "Me"
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
                let profileViewModel = MeProfileViewModel(activeAuthenticationIndex: context.authenticationService.activeAuthenticationIndex.value)
                context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
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
            viewController.tabBarItem.title = nil // set text to nil for image only style
            viewController.tabBarItem.image = tab.image
            viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        context.apiService.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                if let error = error as? APIService.APIError {
                    switch error {
                    case .accountTemporarilyLocked:
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 10)
                        config.interactiveHide = true
                        let bannerView = NotifyBannerView()
                        bannerView.configure(for: .error)
                        bannerView.titleLabel.text = "Account Temporarily Locked"
                        bannerView.messageLabel.text = "Open Twitter to unlock"
                        bannerView.actionButtonTapHandler = { [weak self] button in
                            guard let self = self else { return }
                            let url = URL(string: "https://twitter.com/account/access")!
                            UIApplication.shared.open(url)
                        }
                        SwiftMessages.show(config: config, view: bannerView)
                    default:
                        break
                    }
                }
            }
            .store(in: &disposeBag)
        
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
