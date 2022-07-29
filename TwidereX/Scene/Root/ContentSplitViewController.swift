//
//  ContentSplitViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class ContentSplitViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "ContentSplitViewController", category: "ViewController")

    var disposeBag = Set<AnyCancellable>()
    
    static let sidebarWidth: CGFloat = 80
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
        
    private(set) lazy var sidebarViewController: SidebarViewController = {
        let sidebarViewController = SidebarViewController()
        sidebarViewController.context = context
        sidebarViewController.coordinator = coordinator
        sidebarViewController.viewModel = SidebarViewModel(context: context)
        sidebarViewController.viewModel.delegate = self
        return sidebarViewController
    }()
    
    private(set) lazy var mainTabBarController: MainTabBarController = {
        let mainTabBarController = MainTabBarController(context: context, coordinator: coordinator)
        return mainTabBarController
    }()
    
    private(set) lazy var secondaryTabBarController: SecondaryTabBarController = {
        let secondaryTabBarController = SecondaryTabBarController(context: context, coordinator: coordinator)
        return secondaryTabBarController
    }()
    
    var mainTabBarViewLeadingLayoutConstraint: NSLayoutConstraint!
    
    @Published var isSidebarDisplay = false
    @Published var isSecondaryTabBarControllerActive = false
    
    @Published var tabBarTapScrollPreference = UserDefaults.shared.tabBarTapScrollPreference
    
    // [Tab: HashValue]
    var transformNavigationStackRecord: [TabBarItem: [Int]] = [:]

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ContentSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.shared.publisher(for: \.tabBarTapScrollPreference)
            .removeDuplicates()
            .assign(to: &$tabBarTapScrollPreference)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .opaqueSeparator
        
        addChild(sidebarViewController)
        sidebarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarViewController.view)
        sidebarViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            sidebarViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            sidebarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebarViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarViewController.view.widthAnchor.constraint(equalToConstant: ContentSplitViewController.sidebarWidth),
        ])
        
        addChild(mainTabBarController)
        mainTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainTabBarController.view)
        mainTabBarController.didMove(toParent: self)
        mainTabBarViewLeadingLayoutConstraint = mainTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        NSLayoutConstraint.activate([
            mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainTabBarViewLeadingLayoutConstraint,
            mainTabBarController.view.leadingAnchor.constraint(equalTo: sidebarViewController.view.trailingAnchor, constant: UIView.separatorLineHeight(of: view)).priority(.required - 1),
            mainTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        addChild(secondaryTabBarController)
        secondaryTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(secondaryTabBarController.view)
        secondaryTabBarController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            secondaryTabBarController.view.topAnchor.constraint(equalTo: mainTabBarController.view.topAnchor),
            secondaryTabBarController.view.leadingAnchor.constraint(equalTo: mainTabBarController.view.leadingAnchor),
            secondaryTabBarController.view.trailingAnchor.constraint(equalTo: mainTabBarController.view.trailingAnchor),
            secondaryTabBarController.view.bottomAnchor.constraint(equalTo: mainTabBarController.view.bottomAnchor),
        ])
        secondaryTabBarController.view.isHidden = true
        
        mainTabBarController.$tabs
            .assign(to: &sidebarViewController.viewModel.$mainTabBarItems)
        sidebarViewController.viewModel.activeTab = .home
        sidebarViewController.viewModel.$secondaryTabBarItems
            .assign(to: &secondaryTabBarController.$tabs)
        
        Publishers.CombineLatest(
            $isSidebarDisplay,
            $isSecondaryTabBarControllerActive
        )
        .receive(on: DispatchQueue.main)
        .map { isSidebarDisplay, isSecondaryTabBarControllerActive in
            let needsHidden = !isSidebarDisplay || !isSecondaryTabBarControllerActive
            return needsHidden
        }
        .assign(to: \.isHidden, on: secondaryTabBarController.view)
        .store(in: &disposeBag)
        
        updateConstraint(nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateConstraint(previousTraitCollection)
    }
    
}

extension ContentSplitViewController {
    func select(tab: TabBarItem) {
        sidebarViewController.viewModel.tap(item: tab)
    }
}

extension ContentSplitViewController {

    private func updateConstraint(_ previousTraitCollection: UITraitCollection?) {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            isSidebarDisplay = true
            mainTabBarViewLeadingLayoutConstraint.isActive = false
        default:
            isSidebarDisplay = false
            mainTabBarViewLeadingLayoutConstraint.isActive = true
        }
        
        guard let previousTraitCollection = previousTraitCollection else { return }
        switch (previousTraitCollection.horizontalSizeClass, traitCollection.horizontalSizeClass) {
        case (.regular, .compact):
            // collapse
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): collpase")
            collapse()
                  
        case (.compact, .regular):
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): expand")
            expand()
        default:
            break
        }
    }
    
    private func collapse() {
        guard let from = secondaryTabBarController.selectedViewController as? UINavigationController,
              let to = mainTabBarController.selectedViewController as? UINavigationController,
              let tab = secondaryTabBarController.currentTab
        else { return }
        
        var record: [Int] = []
        let viewControllers = from.popToRootViewController(animated: false) ?? []
        for viewController in viewControllers {
            viewController.navigationItem.hidesBackButton = false
            to.pushViewController(viewController, animated: false)
            record.append(viewController.hashValue)
        }
        transformNavigationStackRecord[tab] = record
    }
    
    private func expand() {
        for _navigationController in mainTabBarController.viewControllers ?? [] {
            guard let navigationController = _navigationController as? UINavigationController else {
                assertionFailure()
                continue
            }
            for (key, values) in transformNavigationStackRecord {
                if let first = navigationController.viewControllers.first(where: { values.contains($0.hashValue) }) {
                    var stack = navigationController.popToViewController(first, animated: false) ?? []
                    navigationController.popViewController(animated: false)
                    stack.insert(first, at: 0)
                    
                    guard let secondaryTabBarNavigationController = secondaryTabBarController.navigationController(for: key) else { continue }
                    stack.first?.navigationItem.hidesBackButton = true
                    for stackItem in stack {
                        secondaryTabBarNavigationController.pushViewController(stackItem, animated: false)
                    }
                    
                } else {
                    continue
                }
            }
        }
        
        transformNavigationStackRecord = [:]
        
        for tab in secondaryTabBarController.tabs {
            guard let secondaryTabBarNavigationController = secondaryTabBarController.navigationController(for: tab) else { continue }
            if secondaryTabBarNavigationController.viewControllers.count == 1 {
                let viewController = tab.viewController(context: context, coordinator: coordinator)
                viewController.navigationItem.hidesBackButton = true
                secondaryTabBarNavigationController.pushViewController(viewController, animated: false)
            }
        }
    }
    
}

// MARK: - SidebarViewModelDelegate
extension ContentSplitViewController: SidebarViewModelDelegate {

    func sidebarViewModel(_ viewModel: SidebarViewModel, didTapItem tab: TabBarItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        switch tab {
        case .settings:
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext else { return }
            let settingListViewModel = SettingListViewModel(
                context: context,
                auth: .init(authenticationContext: authenticationContext)
            )
            coordinator.present(
                scene: .setting(viewModel: settingListViewModel),
                from: nil,
                transition: .modal(animated: true, completion: nil)
            )
        default:
            viewModel.activeTab = tab
            if mainTabBarController.tabs.contains(tab) {
                mainTabBarController.select(tab: tab, isMainTabBarControllerActive: !isSecondaryTabBarControllerActive)
                isSecondaryTabBarControllerActive = false
            } else if secondaryTabBarController.tabs.contains(tab) {
                secondaryTabBarController.select(tab: tab, isSecondaryTabBarControllerActive: isSecondaryTabBarControllerActive)
                isSecondaryTabBarControllerActive = true
            } else {
                assertionFailure()
            }
        }
    }
    
    func sidebarViewModel(_ viewModel: SidebarViewModel, didDoubleTapItem tab: TabBarItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        switch tabBarTapScrollPreference {
        case .single:       return
        case .double:       break
        }

        switch tab {
        case .settings:
            // do nothing
            break
        default:
            guard viewModel.activeTab == tab else { return }
            if mainTabBarController.tabs.contains(tab) {
                mainTabBarController.scrollToTop(tab: tab, isMainTabBarControllerActive: !isSecondaryTabBarControllerActive)
            } else if secondaryTabBarController.tabs.contains(tab) {
                secondaryTabBarController.scrollToTop(tab: tab, isSecondaryTabBarControllerActive: isSecondaryTabBarControllerActive)
            } else {
                assertionFailure()
            }
        }
    }

}
