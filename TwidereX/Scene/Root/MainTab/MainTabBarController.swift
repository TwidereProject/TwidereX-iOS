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
import TwidereCommon

final class MainTabBarController: UITabBarController {
    
    let logger = Logger(subsystem: "MainTabBarController", category: "TabBar")
    
    var disposeBag = Set<AnyCancellable>()
        
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!

    @Published var tabs: [TabBarItem] = [
        .home,
        .notification,
        .search,
        .me,
    ]
    @Published var currentTab: TabBarItem = .home
    
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
    
    override func show(_ vc: UIViewController, sender: Any?) {
        guard let navigationController = selectedViewController as? UINavigationController else {
            super.show(vc, sender: sender)
            return
        }
        
        navigationController.pushViewController(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let viewControllers: [UIViewController] = tabs.map { tab in
            let rootViewController = tab.viewController(context: context, coordinator: coordinator)
            let viewController = AdaptiveStatusBarStyleNavigationController(rootViewController: rootViewController)
            viewController.tabBarItem.tag = tab.tag
            viewController.tabBarItem.title = tab.title
            viewController.tabBarItem.image = tab.image
            viewController.tabBarItem.accessibilityLabel = tab.title
            viewController.tabBarItem.largeContentSizeImage = tab.largeImage
            viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            return viewController
        }
        setViewControllers(viewControllers, animated: false)
        selectedIndex = 0
        
        let feedbackGenerator = UINotificationFeedbackGenerator()

        // post publish result observer
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
        
        Task {
            await setupNotificationTabIconUpdater()
        }   // end Task
        
        let tabBarLongPressGestureRecognizer = UILongPressGestureRecognizer()
        tabBarLongPressGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.tabBarLongPressGestureRecognizerHandler(_:)))
        tabBar.addGestureRecognizer(tabBarLongPressGestureRecognizer)
        
        delegate = self
        
        updateTabBarDisplay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if DEBUG
        //coordinator.present(scene: .displayPreference, from: nil, transition: .show)
        #endif
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateTabBarDisplay()
    }
        
}

extension MainTabBarController {
    
    private var notificationViewController: NotificationViewController? {
        return viewController(of: NotificationViewController.self)
    }
    
    private func updateTabBarDisplay() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            tabBar.isHidden = false
        default:
            tabBar.isHidden = true
        }
    }
    
    @MainActor
    private func setupNotificationTabIconUpdater() async {
        // notification tab bar icon updater
        await Publishers.CombineLatest3(
            context.authenticationService.$activeAuthenticationContext,
            context.notificationService.unreadNotificationCountDidUpdate,   // <-- actor property
            $currentTab
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authenticationContext, _, currentTab in
            guard let self = self else { return }
            guard let authenticationContext = authenticationContext else { return }
            guard let notificationViewController = self.notificationViewController else { return }

            let hasUnreadPushNotification: Bool = {
                switch authenticationContext {
                case .twitter:
                    return false
                case .mastodon(let authenticationContext):
                    let accessToken = authenticationContext.authorization.accessToken
                    let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                    return count > 0
                }
            }()
            let image = hasUnreadPushNotification ? Asset.ObjectTools.bellRinging.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectTools.bell.image.withRenderingMode(.alwaysTemplate)
            let largeImage = hasUnreadPushNotification ? Asset.ObjectTools.bellRingingLarge.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectTools.bellLarge.image.withRenderingMode(.alwaysTemplate)
            
            notificationViewController.tabBarItem.image = image
            notificationViewController.tabBarItem.largeContentSizeImage = largeImage
            
            notificationViewController.navigationController?.tabBarItem.image = image
            notificationViewController.navigationController?.tabBarItem.largeContentSizeImage = largeImage
        }
        .store(in: &disposeBag)
    }

}

extension MainTabBarController {

    func select(tab: TabBarItem, isMainTabBarControllerActive: Bool = true) {
        let _index = tabBar.items?.firstIndex(where: { $0.tag == tab.tag })
        guard let index = _index else {
            return
        }
        
        defer {
            selectedIndex = index
            currentTab = tab
        }
        
        // check if selected and scroll it to top or pop to top
        guard isMainTabBarControllerActive,
              currentTab == tab,
              let viewController = viewControllers?[safe: index],
              let navigationController = viewController as? UINavigationController
        else { return }
        
        guard navigationController.viewControllers.count == 1 else {
            navigationController.popToRootViewController(animated: true)
            return
        }

        let _scrollViewContainer = (navigationController.topViewController as? ScrollViewContainer) ?? (navigationController.topMost as? ScrollViewContainer)
        guard let scrollViewContainer = _scrollViewContainer else {
            return
        }
        scrollViewContainer.scrollToTop(animated: true)
    }
    
}

extension MainTabBarController {
    
    @objc private func tabBarLongPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }

        var _tab: TabBarItem?
        let location = sender.location(in: tabBar)
        for item in tabBar.items ?? [] {
            guard let tab = TabBarItem(rawValue: item.tag) else { continue }
            guard let view = item.value(forKey: "view") as? UIView else { continue }
            guard view.frame.contains(location) else { continue}

            _tab = tab
            break
        }

        guard let tab = _tab else { return }
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): long press \(tab.title) tab")

        switch tab {
        case .me:
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            let accountListViewModel = AccountListViewModel(context: context)
            coordinator.present(scene: .accountList(viewModel: accountListViewModel), from: self, transition: .modal(animated: true, completion: nil))
        default:
            break
        }
    }

}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let tab = TabBarItem(rawValue: viewController.tabBarItem.tag) else {
            assertionFailure()
            return
        }
        
        select(tab: tab)
    }
}
