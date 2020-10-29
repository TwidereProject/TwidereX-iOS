//
//  MainTabBarController.swift
//  TwidereX
//
//  Created by jk234ert on 8/10/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    
    enum Tab: Int, CaseIterable {
        case timeline
        case search
        case me
        
        var title: String {
            switch self {
            case .timeline:     return "Timeline"
            case .search:       return "Search"
            case .me:           return "Me"
            }
        }
        
        var image: UIImage {
            switch self {
            case .timeline:     return Asset.ObjectTools.house.image.withRenderingMode(.alwaysTemplate)
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
            case .search:
                let _viewController = SearchViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                viewController = _viewController
            case .me:
                let _viewController = ProfileViewController()
                _viewController.context = context
                _viewController.coordinator = coordinator
                _viewController.viewModel = MeProfileViewModel(context: context)
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
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        #if DEBUG
        // selectedIndex = 1
        #endif
    }
    
}
