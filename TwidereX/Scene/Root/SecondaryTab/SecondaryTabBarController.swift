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
import TwidereCore
import func QuartzCore.CACurrentMediaTime

final class SecondaryTabBarController: UITabBarController {
    
    let logger = Logger(subsystem: "MainTabBarController", category: "TabBar")

    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
    let authContext: AuthContext
    
    @Published var tabs: [TabBarItem] = [] {
        didSet {
            update(tabs: tabs)
        }
    }
    @Published var currentTab: TabBarItem?
    
    static var popToRootAfterActionTolerance: TimeInterval { 0.5 }
    var lastPopToRootTime = CACurrentMediaTime()
    @Published var tabBarTapScrollPreference = UserDefaults.shared.tabBarTapScrollPreference

    init(context: AppContext, coordinator: SceneCoordinator, authContext: AuthContext) {
        self.context = context
        self.coordinator = coordinator
        self.authContext = authContext
        super.init(nibName: nil, bundle: nil)
        
        UserDefaults.shared.publisher(for: \.tabBarTapScrollPreference)
            .removeDuplicates()
            .assign(to: &$tabBarTapScrollPreference)
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

    func select(tab: TabBarItem, isSecondaryTabBarControllerActive: Bool = true) {
        let _index = tabBar.items?.firstIndex(where: { $0.tag == tab.tag })
        guard let index = _index else {
            return
        }
        
        defer {
            selectedIndex = index
            currentTab = tab

        }
        
        guard popToRoot(tab: tab, isSecondaryTabBarControllerActive: isSecondaryTabBarControllerActive) else { return }
        
        // check if preferred double tap for scrollToTop
        switch tabBarTapScrollPreference {
        case .single:       break
        case .double:       return
        }
        
        scrollToTop(tab: tab, isSecondaryTabBarControllerActive: isSecondaryTabBarControllerActive)
    }
    
    func popToRoot(tab: TabBarItem, isSecondaryTabBarControllerActive: Bool = true) -> Bool {
        let _index = tabBar.items?.firstIndex(where: { $0.tag == tab.tag })
        guard let index = _index else {
            return false
        }
        
        // check if selected and pop it to root
        guard isSecondaryTabBarControllerActive,
              currentTab == tab,
              let viewController = viewControllers?[safe: index],
              let navigationController = viewController as? UINavigationController
        else { return false }
        
        // additional prepend SecondaryTabBarRootController
        guard navigationController.viewControllers.count == 1 + 1 else {
            if let second = navigationController.viewControllers[safe: 1] {
                navigationController.popToViewController(second, animated: true)
                lastPopToRootTime = CACurrentMediaTime()
            }
            return false
        }
        
        return true
    }
    
    func scrollToTop(tab: TabBarItem, isSecondaryTabBarControllerActive: Bool = true) {
        let now = CACurrentMediaTime()
        guard now - lastPopToRootTime > SecondaryTabBarController.popToRootAfterActionTolerance else { return }
        
        let _index = tabBar.items?.firstIndex(where: { $0.tag == tab.tag })
        guard let index = _index else {
            return
        }
        
        // check if selected and scroll it to top
        guard isSecondaryTabBarControllerActive,
              currentTab == tab,
              let viewController = viewControllers?[safe: index],
              let navigationController = viewController as? UINavigationController
        else { return }

        guard navigationController.viewControllers.count == 1 + 1 else {
            return
        }

        let _scrollViewContainer = (navigationController.topViewController as? ScrollViewContainer) ?? (navigationController.topMost as? ScrollViewContainer)
        guard let scrollViewContainer = _scrollViewContainer else {
            return
        }
        scrollViewContainer.scrollToTop(animated: true)
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
            let viewController = AdaptiveStatusBarStyleNavigationController(rootViewController: SecondaryTabBarRootController())
            let _rootViewController = tab.viewController(context: context, coordinator: coordinator, authContext: authContext)
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
