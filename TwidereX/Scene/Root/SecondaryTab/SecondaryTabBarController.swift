//
//  SecondaryTabBarController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-5-5.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import UIKit
import Combine

final class SecondaryTabBarController: UITabBarController {
    
    let logger = Logger(subsystem: "MainTabBarController", category: "TabBar")

    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    
    @Published var tabs: [TabBarItem] = [] {
        didSet {
            update(tabs: tabs)
        }
    }
    @Published var currentTab: TabBarItem?
    

    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension SecondaryTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.isHidden = true
        
        $tabs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tabs in
                guard let self = self else { return }
                self.update(tabs: tabs)
            }
            .store(in: &disposeBag)
    }
    
}


extension SecondaryTabBarController {

    func select(tab: TabBarItem) {
        let _index = tabBar.items?.firstIndex(where: { $0.tag == tab.tag })
        if let index = _index {
            selectedIndex = index
        }
        
        currentTab = tab
    }
    
    func navigationController(for tab: TabBarItem) -> UINavigationController? {
        for (_tab, viewController) in zip(tabs, viewControllers ?? []) {
            guard tab == _tab else { continue }
            return viewController as? UINavigationController
        }
        
        return nil
    }
    
}

extension SecondaryTabBarController {
    private func update(tabs: [TabBarItem]) {
        let viewControllers: [UIViewController] = tabs.map { tab in
            let viewController = UINavigationController(rootViewController: SecondaryTabBarRootController())
            let _rootViewController = tab.viewController(context: context, coordinator: coordinator)
            _rootViewController.navigationItem.hidesBackButton = true
            viewController.pushViewController(_rootViewController, animated: false)
            viewController.tabBarItem.tag = tab.tag
            viewController.tabBarItem.title = tab.title
            viewController.tabBarItem.image = tab.image
            viewController.tabBarItem.accessibilityLabel = tab.title
            viewController.tabBarItem.largeContentSizeImage = tab.largeImage
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
    }
}
