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
//        if let homeTimelineViewController = mainTabBarController.viewController(of: HomeTimelineViewController.self) {
//            homeTimelineViewController.viewModel.displayComposeBarButtonItem = false
//            homeTimelineViewController.viewModel.displaySettingBarButtonItem = false
//        }
        return mainTabBarController
    }()
    
    var mainTabBarViewLeadingLayoutConstraint: NSLayoutConstraint!

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ContentSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        sidebarViewController.didMove(toParent: self)
        mainTabBarViewLeadingLayoutConstraint = mainTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        NSLayoutConstraint.activate([
            mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainTabBarViewLeadingLayoutConstraint,
            mainTabBarController.view.leadingAnchor.constraint(equalTo: sidebarViewController.view.trailingAnchor, constant: UIView.separatorLineHeight(of: view)).priority(.required - 1),
            mainTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        mainTabBarController.$currentTab
            .receive(on: DispatchQueue.main)
            .assign(to: \.activeTab, on: sidebarViewController.viewModel)
            .store(in: &disposeBag)
        
        updateConstraint()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateConstraint()
    }
    
}

extension ContentSplitViewController {

    private func updateConstraint() {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            mainTabBarViewLeadingLayoutConstraint.isActive = false
        case .compact, .unspecified:
            mainTabBarViewLeadingLayoutConstraint.isActive = true
        @unknown default:
            assertionFailure()
            mainTabBarViewLeadingLayoutConstraint.isActive = true
        }
    }
    
}

// MARK: - SidebarViewModelDelegate
extension ContentSplitViewController: SidebarViewModelDelegate {

    func sidebarViewModel(_ viewModel: SidebarViewModel, active item: SidebarViewModel.Item) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        switch item {
        case .tab(let tab):
            viewModel.activeTab = tab
            mainTabBarController.select(tab: tab)
        case .entry(let entry):
            let from = mainTabBarController
            switch entry {
            case .local:
                let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, local: true)
                coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: from, transition: .show)
            case .federated:
                let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, local: false)
                coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: from, transition: .show)
            case .likes:
                let meLikeTimelineViewModel = MeLikeTimelineViewModel(context: context)
                coordinator.present(scene: .userLikeTimeline(viewModel: meLikeTimelineViewModel), from: from, transition: .show)
            case .lists:
                guard let me = context.authenticationService.activeAuthenticationContext?.user(in: context.managedObjectContext)?.asRecord else { return }
                
                let compositeListViewModel = CompositeListViewModel(
                    context: context,
                    kind: .lists(me)
                )
                coordinator.present(
                    scene: .compositeList(viewModel: compositeListViewModel),
                    from: from,
                    transition: .show
                )
            case .settings:
                coordinator.present(scene: .setting, from: from, transition: .modal(animated: true, completion: nil))
            default:
                assertionFailure()
            }   // end switch entry
        }   // end switch item
    }

}

