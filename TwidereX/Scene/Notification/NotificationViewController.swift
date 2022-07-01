//
//  NotificationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Tabman
import Pageboy

final class NotificationViewController: TabmanViewController, NeedsDependency, DrawerSidebarTransitionHostViewController {

    let logger = Logger(subsystem: "NotificationViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = NotificationViewModel(context: context, coordinator: coordinator)
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    private(set) lazy var pageSegmentedControl = UISegmentedControl()
    
    override func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: TabmanViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        super.pageboyViewController(
            pageboyViewController,
            didScrollToPageAt: index,
            direction: direction,
            animated: animated
        )
        
        viewModel.currentPageIndex = index
        
        #if DEBUG
        setupDebugAction()
        #endif
    }

}

extension NotificationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isScrollEnabled = false     // inner pan gesture untouchable. workaround to prevent swipe conflict
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)

        view.backgroundColor = .systemBackground
        
        if navigationController?.viewControllers.first == self {
            coordinator.$needsSetupAvatarBarButtonItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] needsSetupAvatarBarButtonItem in
                    guard let self = self else { return }
                    self.navigationItem.leftBarButtonItem = needsSetupAvatarBarButtonItem ? self.avatarBarButtonItem : nil
                }
                .store(in: &disposeBag)            
        }
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(NotificationViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        avatarBarButtonItem.delegate = self
        
        Publishers.CombineLatest(
            context.authenticationService.$activeAuthenticationContext,
            viewModel.viewDidAppear
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authenticationContext, _ in
            guard let self = self else { return }
            let user = authenticationContext?.user(in: self.context.managedObjectContext)
            self.avatarBarButtonItem.configure(user: user)
        }
        .store(in: &disposeBag)
        
        dataSource = viewModel
        viewModel.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewControllers in
                guard let self = self else { return }
                self.reloadData()
                self.bounces = viewControllers.count > 1
                
            }
            .store(in: &disposeBag)
        
        setupSegmentedControl(scopes: viewModel.scopes)
        viewModel.$scopes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scopes in
                guard let self = self else { return }
                self.setupSegmentedControl(scopes: scopes)
                self.navigationItem.titleView = scopes.count > 1 ? self.pageSegmentedControl : nil
            }
            .store(in: &disposeBag)
        
        viewModel.$currentPageIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentPageIndex in
                guard let self = self else { return }
                if self.pageSegmentedControl.selectedSegmentIndex != currentPageIndex {
                    self.pageSegmentedControl.selectedSegmentIndex = currentPageIndex
                }
            }
            .store(in: &disposeBag)
        
        pageSegmentedControl.addTarget(self, action: #selector(NotificationViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
}

extension NotificationViewController {

    @objc private func avatarButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let drawerSidebarViewModel = DrawerSidebarViewModel(context: context)
        coordinator.present(scene: .drawerSidebar(viewModel: drawerSidebarViewModel), from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
}


#if DEBUG
extension NotificationViewController {
    func setupDebugAction() {
        guard let index = currentIndex,
              index < viewModel.viewControllers.count
        else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        let viewController = viewModel.viewControllers[index]
        
        if let viewController = viewController as? NotificationTimelineViewController {
            navigationItem.rightBarButtonItem = viewController.debugActionBarButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
}
#endif

extension NotificationViewController {
    private func setupSegmentedControl(scopes: [NotificationTimelineViewModel.Scope]) {
        pageSegmentedControl.removeAllSegments()
        for (i, scope) in scopes.enumerated() {
            pageSegmentedControl.insertSegment(withTitle: scope.title, at: i, animated: false)
        }
        
        // set initial selection
        guard !pageSegmentedControl.isSelected else { return }
        if viewModel.currentPageIndex < pageSegmentedControl.numberOfSegments {
            pageSegmentedControl.selectedSegmentIndex = viewModel.currentPageIndex
        } else {
            pageSegmentedControl.selectedSegmentIndex = 0
        }
    }
}

extension NotificationViewController {
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let index = sender.selectedSegmentIndex
        scrollToPage(.at(index: index), animated: true, completion: nil)
    }
}

// MARK: - AvatarBarButtonItemDelegate
extension NotificationViewController: AvatarBarButtonItemDelegate { }

