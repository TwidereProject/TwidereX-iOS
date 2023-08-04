//
//  SecondaryContainerViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2023/5/22.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit

final class SecondaryContainerViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    let authContext: AuthContext
    
    public private(set) lazy var viewModel = SecondaryContainerViewModel(context: context, auth: authContext)
    
    let containerScrollView = UIScrollView()
    let stack = UIStackView()
        
    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        authContext: AuthContext
    ) {
        self.context = context
        self.coordinator = coordinator
        self.authContext = authContext
        super.init(nibName: nil, bundle: nil)
        // end init
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SecondaryContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerScrollView.frame = view.bounds
        containerScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerScrollView)
        NSLayoutConstraint.activate([
            containerScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            containerScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerScrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerScrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        stack.axis = .horizontal
        stack.spacing = UIView.separatorLineHeight(of: view)
        stack.alignment = .leading
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.heightAnchor),
        ])
        
        setupNewColumn()
    }
    
}

extension SecondaryContainerViewController {
    private func setupNewColumn() {
        let newColumnViewController = NewColumnViewController(
            context: context,
            coordinator: coordinator,
            authContext: authContext
        )
        newColumnViewController.viewModel.delegate = self
        viewModel.addColumn(
            in: stack,
            tab: nil,
            viewController: newColumnViewController,
            setupColumnMenu: false
        )
    }
}

// MARK: - NewColumnViewDelegate
extension SecondaryContainerViewController: NewColumnViewDelegate {
    func newColumnView(_ viewModel: NewColumnViewModel, tabBarItemDidPressed tab: TabBarItem) {
        guard let viewController = self.viewController(for: tab) else {
            assertionFailure()
            return
        }
        
        self.viewModel.addColumn(
            in: stack,
            tab: tab,
            viewController: viewController,
            newColumnViewModel: viewModel
        )
    }
    
    private func menuActionForOpenTabs(tabs: [TabBarItem], exclude: TabBarItem) -> [TabBarItem] {
        var tabs = tabs
        tabs.removeAll(where: { $0 == exclude })
        return tabs
    }
    
    private func configure(viewController: NeedsDependency) {
        viewController.context = context
        viewController.coordinator = coordinator
    }
    
    private func viewController(for tab: TabBarItem) -> UIViewController? {
        switch tab {
        case .home:
            let homeTimelineViewController = HomeTimelineViewController()
            configure(viewController: homeTimelineViewController)
            homeTimelineViewController.viewModel = HomeTimelineViewModel(
                context: context,
                authContext: authContext
            )
            return homeTimelineViewController
        case .homeList:
            assertionFailure()
            return nil
        case .notification:
            let notificationViewController = NotificationViewController()
            configure(viewController: notificationViewController)
            notificationViewController.viewModel = NotificationViewModel(
                context: context,
                authContext: authContext,
                coordinator: coordinator
            )
            return notificationViewController
        case .search:
            let searchViewController = SearchViewController()
            configure(viewController: searchViewController)
            searchViewController.viewModel = SearchViewModel(
                context: context,
                authContext: authContext
            )
            return searchViewController
        case .me:
            let profileViewController = ProfileViewController()
            configure(viewController: profileViewController)
            profileViewController.viewModel = MeProfileViewModel(
                context: context,
                authContext: authContext
            )
            return profileViewController
        case .local:
            let federatedTimelineViewModel = FederatedTimelineViewModel(
                context: context,
                authContext: authContext,
                isLocal: true
            )
            guard let rootViewController = coordinator.get(scene: .federatedTimeline(viewModel: federatedTimelineViewModel)) else { return nil }
            return rootViewController
        case .federated:
            let federatedTimelineViewModel = FederatedTimelineViewModel(
                context: context,
                authContext: authContext,
                isLocal: false
            )
            guard let rootViewController = coordinator.get(scene: .federatedTimeline(viewModel: federatedTimelineViewModel)) else { return nil }
            return rootViewController
        case .messages:
            assertionFailure()
            return nil
        case .likes:
            let userLikeTimelineViewModel = UserLikeTimelineViewModel(
                context: context,
                authContext: authContext,
                timelineContext: .init(
                    timelineKind: .like,
                    protected: {
                        guard let user = authContext.authenticationContext.user(in: context.managedObjectContext) else { return false }
                        return user.protected
                    }(),
                    userIdentifier: authContext.authenticationContext.userIdentifier
                )
            )
            userLikeTimelineViewModel.isFloatyButtonDisplay = false
            guard let rootViewController = coordinator.get(scene: .userLikeTimeline(viewModel: userLikeTimelineViewModel)) else { return nil }
            return rootViewController
        case .history:
            let historyViewModel = HistoryViewModel(
                context: context,
                coordinator: coordinator,
                authContext: authContext
            )
            guard let rootViewController = coordinator.get(scene: .history(viewModel: historyViewModel)) else { return nil }
            return rootViewController
        case .lists:
            guard let me = authContext.authenticationContext.user(in: context.managedObjectContext)?.asRecord else { return nil }

            let compositeListViewModel = CompositeListViewModel(
                context: context,
                authContext: authContext,
                kind: .lists(me)
            )
            guard let rootViewController = coordinator.get(scene: .compositeList(viewModel: compositeListViewModel)) else { return nil }
            return rootViewController
        case .trends:
            let trendViewModel = TrendViewModel(
                context: context,
                authContext: authContext
            )
            guard let rootViewController = coordinator.get(scene: .trend(viewModel: trendViewModel)) else { return nil }
            return rootViewController
        case .drafts:
            assertionFailure()
            return nil
        case .settings:
            assertionFailure()
            return nil
        }
    }
    
    func newColumnView(
        _ viewModel: NewColumnViewModel,
        source: UINavigationController,
        openTabMenuAction tab: TabBarItem
    ) {
        guard let index = self.viewModel.removeColumn(in: stack, navigationController: source) else { return }
        guard let viewController = self.viewController(for: tab) else { return }
        self.viewModel.addColumn(
            in: stack,
            at: index,
            tab: tab,
            viewController: viewController,
            newColumnViewModel: viewModel
        )
    }
}
