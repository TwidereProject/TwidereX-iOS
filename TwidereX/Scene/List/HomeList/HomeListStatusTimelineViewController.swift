//
//  HomeListStatusTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2023/4/26.
//  Copyright © 2023 Twidere. All rights reserved.
//

import os.log
import UIKit
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
    
    var listStatusTimelineViewController: ListStatusTimelineViewController?
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
            
            let menuContext = self.viewModel.createHomeListMenuContext()
            
            var children: [UIMenuElement] = [
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

        let newList = activeMenuActionViewModel.list.asRecord
        var isSameList: Bool {
            guard let viewModel = listStatusTimelineViewController?.viewModel as? ListStatusTimelineViewModel else { return false }
            return viewModel.list == newList
        }
        guard !isSameList else { return }
        
        // detach
        detachTimeline()
        
        // attach
        let viewController = ListStatusTimelineViewController()
        viewController.context = context
        viewController.coordinator = coordinator
        viewController.viewModel = ListStatusTimelineViewModel(
            context: context,
            authContext: authContext,
            list: activeMenuActionViewModel.list.asRecord
        )
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
        let list = menuActionViewModel.list.asRecord
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
    }   // end func
}
