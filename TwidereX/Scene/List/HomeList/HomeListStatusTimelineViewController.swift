//
//  HomeListStatusTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2023/4/26.
//  Copyright © 2023 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereLocalization

final class HomeListStatusTimelineViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionHostViewController, MediaPreviewableViewController {
        
    let logger = Logger(subsystem: "HomeListStatusTimelineViewController", category: "ViewController")

    // MARK: NeedsDependency
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    // MARK: DrawerSidebarTransitionHostViewController
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    // MARK: MediaPreviewTransitionHostViewController
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
 
    public var viewModel: HomeListStatusTimelineViewModel!
    var disposeBag = Set<AnyCancellable>()
    
    let emptyStateViewModel = EmptyStateView.ViewModel()
    
    @Published var listStatusTimelineViewController: ListTimelineViewController?
}

extension HomeListStatusTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)

        view.backgroundColor = .systemBackground
        
        // setup avatarBarButtonItem
        if navigationController?.viewControllers.first == self {
            coordinator.$needsSetupAvatarBarButtonItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] needsSetupAvatarBarButtonItem in
                    guard let self = self else { return }
                    if let leftBarButtonItem = self.navigationItem.leftBarButtonItem,
                       leftBarButtonItem !== self.avatarBarButtonItem
                    {
                        // allow override
                        return
                    }
                    self.navigationItem.leftBarButtonItem = needsSetupAvatarBarButtonItem ? self.avatarBarButtonItem : nil
                }
                .store(in: &disposeBag)
        }
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(HomeListStatusTimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        avatarBarButtonItem.delegate = self
        
        viewModel.delegate = self
        viewModel.viewDidAppear
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let user = self.viewModel.authContext.authenticationContext.user(in: self.context.managedObjectContext)
                self.avatarBarButtonItem.configure(user: user)
            }
            .store(in: &disposeBag)

        navigationItem.titleMenuProvider = { [weak self] _ -> UIMenu? in
            guard let self = self else { return nil }
            
            defer {
                self.reloadList()
            }
            
            let menuContext = self.viewModel.createHomeListMenuContext()
            
            var children: [UIMenuElement] = [
                menuContext.homeTimelineMenu,
                menuContext.ownedListMenu,
                menuContext.subscribedListMenu,
            ]
            
            if menuContext.isEmpty {
                let deferredMenuElement = UIDeferredMenuElement.uncached { handler in
                    Task {
                        let manageListAction = UIAction(title: "Manage List", image: UIImage(systemName: "list.bullet")) { [weak self] _ in
                            guard let self = self else { return }
                            guard let me = self.authContext.authenticationContext.user(in: self.context.managedObjectContext)?.asRecord else { return }
                            let compositeListViewModel = CompositeListViewModel(
                                context: self.context,
                                authContext: self.authContext,
                                kind: .lists(me)
                            )
                            self.coordinator.present(scene: .compositeList(viewModel: compositeListViewModel), from: self, transition: .show)
                        }
                        handler([manageListAction])
                    }   // end Task
                }
                children.append(deferredMenuElement)
            }
            
            // root menu
            return UIMenu(children: children)
        }
        
        viewModel.$homeListMenuContext
            .sink { [weak self] menuContext in
                guard let self = self else { return }
                self.attachTimelineViewController(menuContext: menuContext)
            }
            .store(in: &disposeBag)
        
        let emptyStateViewHostingController = UIHostingController(rootView: EmptyStateView(viewModel: emptyStateViewModel))
        addChild(emptyStateViewHostingController)
        emptyStateViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewHostingController.view)
        NSLayoutConstraint.activate([
            emptyStateViewHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateViewHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateViewHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        emptyStateViewHostingController.view.isHidden = true
        emptyStateViewModel.$emptyState
            .map { $0 == nil }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: emptyStateViewHostingController.view)
            .store(in: &disposeBag)
        
        $listStatusTimelineViewController
            .map { $0 == nil ? EmptyState.homeListNotSelected : nil }
            .receive(on: DispatchQueue.main)
            .assign(to: \.emptyState, on: emptyStateViewModel)
            .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
}

extension HomeListStatusTimelineViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let drawerSidebarViewModel = DrawerSidebarViewModel(context: context, authContext: viewModel.authContext)
        coordinator.present(scene: .drawerSidebar(viewModel: drawerSidebarViewModel), from: self, transition: .custom(animated: true, transitioningDelegate: drawerSidebarTransitionController))
    }
    
    private func selectListMenuAction(_ viewModel: HomeListStatusTimelineViewModel.HomeListMenuActionViewModel) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
    private func attachTimelineViewController(menuContext: HomeListStatusTimelineViewModel.HomeListMenuContext?) {
        guard let menuContext = menuContext,
              let activeMenuActionViewModel = menuContext.activeMenuActionViewModel
        else {
            detachTimeline()
            return
        }

        var isSameTimeline: Bool {
            switch activeMenuActionViewModel.timeline {
            case .home:
                guard let _ = listStatusTimelineViewController?.viewModel as? HomeTimelineViewModel else { return false }
                return true
            case .list(let list):
                guard let viewModel = listStatusTimelineViewController?.viewModel as? ListStatusTimelineViewModel else { return false }
                return viewModel.list == list.asRecord
            }
        }
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): isSameTimeline: \(isSameTimeline)")
        guard !isSameTimeline else { return }
        
        // detach
        detachTimeline()
        
        // attach
        let viewController: ListTimelineViewController = {
            switch activeMenuActionViewModel.timeline {
            case .home:
                let viewController = HomeTimelineViewController()
                viewController.context = context
                viewController.coordinator = coordinator
                viewController.viewModel = HomeTimelineViewModel(
                    context: context,
                    authContext: authContext
                )
                return viewController
            case .list(let list):
                let viewController = ListStatusTimelineViewController()
                viewController.context = context
                viewController.coordinator = coordinator
                viewController.viewModel = ListStatusTimelineViewModel(
                    context: context,
                    authContext: authContext,
                    list: list.asRecord
                )
                return viewController
            }
        }()
        self.listStatusTimelineViewController = viewController
        self.title = activeMenuActionViewModel.title
        
        addChild(viewController)
        viewController.willMove(toParent: self)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        viewController.didMove(toParent: self)
    }
    
    private func detachTimeline() {
        listStatusTimelineViewController?.willMove(toParent: nil)
        listStatusTimelineViewController?.view.removeFromSuperview()
        listStatusTimelineViewController?.didMove(toParent: nil)
        listStatusTimelineViewController?.removeFromParent()
        title = L10n.Scene.Timeline.title
    }
    
    private func reloadList() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): reload owned list")
        viewModel.ownedListViewModel.stateMachine.enter(ListViewModel.State.Reloading.self)
    }
    
}

// MARK: - AuthContextProvider
extension HomeListStatusTimelineViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - AvatarBarButtonItemDelegate
extension HomeListStatusTimelineViewController: AvatarBarButtonItemDelegate { }

// MARK: - HomeListStatusTimelineViewModelDelegate
extension HomeListStatusTimelineViewController: HomeListStatusTimelineViewModelDelegate {
    func homeListStatusTimelineViewModel(
        _ viewModel: HomeListStatusTimelineViewModel,
        menuActionDidSelect menuActionViewModel: HomeListStatusTimelineViewModel.HomeListMenuActionViewModel
    ) {
        switch menuActionViewModel.timeline {
        case .home(let authenticationIndex):
            let authenticationIndex = authenticationIndex.asRecrod
            let managedObjectContext = context.backgroundManagedObjectContext
            Task {
                let now = Date()
                try await managedObjectContext.performChanges {
                    guard let object = authenticationIndex.object(in: managedObjectContext) else { return }
                    object.update(homeTimelineActiveAt: now)
                }
                self.viewModel.homeTimelineMenuActionViewModels.first?.activeAt = now
                self.viewModel.createHomeListMenuContext()
            }   // end Task
        case .list(let list):
            let list = list.asRecord
            let managedObjectContext = context.backgroundManagedObjectContext
            Task {
                try await managedObjectContext.performChanges {
                    guard let object = list.object(in: managedObjectContext) else { return }
                    switch object {
                    case .twitter(let object):
                        object.update(activeAt: Date())
                    case .mastodon(let object):
                        object.update(activeAt: Date())
                    }   // end switch
                }
                self.viewModel.createHomeListMenuContext()
            }   // end Task
        }
    }   // end func
}
