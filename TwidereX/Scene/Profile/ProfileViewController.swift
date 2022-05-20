//
//  ProfileViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import AppShared
import Floaty
import Meta
import MetaTextArea
import MetaTextKit
import TabBarPager
import XLPagerTabStrip
import TwidereUI

final class ProfileViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionHostViewController {
    
    let logger = Logger(subsystem: "ProfileViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    let moreMenuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), style: .plain, target: nil, action: nil)
        return barButtonItem
    }()
    
    let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        return refreshControl
    }()
    
    private(set) lazy var tabBarPagerController = TabBarPagerController()

    private(set) lazy var profileHeaderViewController: ProfileHeaderViewController = {
        let profileHeaderViewController = ProfileHeaderViewController()
        profileHeaderViewController.viewModel = ProfileHeaderViewModel(context: context)
        profileHeaderViewController.delegate = self
        return profileHeaderViewController
    }()
    private(set) lazy var profilePagingViewController: ProfilePagingViewController = {
        let profilePagingViewController = ProfilePagingViewController()
        
        let userTimelineViewModel = UserTimelineViewModel(context: context)
        viewModel.$userIdentifier
            .assign(to: &userTimelineViewModel.$userIdentifier)
        
        let userMediaTimelineViewModel = UserMediaTimelineViewModel(context: context)
        viewModel.$userIdentifier
            .assign(to: &userMediaTimelineViewModel.$userIdentifier)
        
        let userLikeTimelineViewModel = UserLikeTimelineViewModel(context: context)
        viewModel.$userIdentifier
            .assign(to: &userLikeTimelineViewModel.$userIdentifier)
        
        profilePagingViewController.viewModel = {
            let profilePagingViewModel = ProfilePagingViewModel(
                userTimelineViewModel: userTimelineViewModel,
                userMediaTimelineViewModel: userMediaTimelineViewModel,
                userLikeTimelineViewModel: userLikeTimelineViewModel
            )
            profilePagingViewModel.viewControllers.forEach { viewController in
                if let viewController = viewController as? NeedsDependency {
                    viewController.context = context
                    viewController.coordinator = coordinator
                }
            }
            return profilePagingViewModel
        }()
        return profilePagingViewController
    }()
    
    private lazy var floatyButton: Floaty = {
        let button = Floaty()
        button.plusColor = .white
        button.buttonColor = ThemeService.shared.theme.value.accentColor
        button.buttonImage = Asset.Arrows.arrowshapeTurnUpLeftFill.image.withTintColor(.white)
        button.handleFirstItemDirectly = true
        
        let composeItem: FloatyItem = {
            let item = FloatyItem()
            item.title = L10n.Scene.Compose.Title.reply
            item.handler = { [weak self] item in
                guard let self = self else { return }
                self.floatyButtonPressed(item)
            }
            return item
        }()
        button.addItem(item: composeItem)
        
        return button
    }()
        
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(ProfileViewController.avatarButtonPressed(_:)), for: .touchUpInside)
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
        }
        
        addChild(tabBarPagerController)
        tabBarPagerController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarPagerController.view)
        tabBarPagerController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            tabBarPagerController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabBarPagerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarPagerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarPagerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        view.addSubview(floatyButton)
        viewModel.relationshipViewModel.$isMyself
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMyself in
                guard let self = self else { return }
                let image = isMyself ? Asset.Editing.featherPen.image : Asset.Arrows.arrowshapeTurnUpLeftFill.image.withTintColor(.white)
                self.floatyButton.buttonImage = image
            }
            .store(in: &disposeBag)
        
        tabBarPagerController.delegate = self
        tabBarPagerController.dataSource = self
        Publishers.CombineLatest(
            viewModel.$user,
            viewModel.$me
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] user, me in
            guard let self = self else { return }
            guard let user = user, let me = me else { return }
            
            // set like timeline display
            switch (user, me) {
            case (.mastodon(let userObject), .mastodon(let meObject)):
                self.profilePagingViewController.viewModel.displayLikeTimeline = userObject.objectID == meObject.objectID
            default:
                self.profilePagingViewController.viewModel.displayLikeTimeline = true
            }
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            viewModel.relationshipViewModel.$optionSet,  // update trigger
            viewModel.$userRecord,
            context.authenticationService.$activeAuthenticationContext
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] optionSet, userRecord, authenticationContext in
            guard let self = self else { return }
            guard let userRecord = userRecord,
                  let authenticationContext = authenticationContext
            else {
                self.moreMenuBarButtonItem.menu = nil
                self.navigationItem.rightBarButtonItems = []
                return
            }
            Task {
                do {
                    let menu = try await DataSourceFacade.createMenuForUser(
                        provider: self,
                        user: userRecord,
                        authenticationContext: authenticationContext
                    )
                    self.moreMenuBarButtonItem.menu = menu
                    
                    self.navigationItem.rightBarButtonItems = {
                        var items: [UIBarButtonItem] = []
                        if !menu.children.isEmpty {
                            items.append(self.moreMenuBarButtonItem)
                        }
                        return items
                    }()
                } catch {
                    self.moreMenuBarButtonItem.menu = nil
                    self.navigationItem.rightBarButtonItems = []
                    assertionFailure()
                }
            }
        }
        .store(in: &disposeBag)

        tabBarPagerController.relayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        // bind view model
        viewModel.$user
            .assign(to: &profileHeaderViewController.viewModel.$user)
        viewModel.relationshipViewModel.$optionSet
            .assign(to: &profileHeaderViewController.viewModel.$relationshipOptionSet)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.floatyButton.paddingY = self.view.safeAreaInsets.bottom + UIView.floatyButtonBottomMargin
        }
    }
    
}

extension ProfileViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let drawerSidebarViewModel = DrawerSidebarViewModel(context: context)
        coordinator.present(scene: .drawerSidebar(viewModel: drawerSidebarViewModel), from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): <#message#>")
        
        let currentPage = profilePagingViewController.currentPage
        if let currentPage = currentPage as? UserTimelineViewController {
            currentPage.viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
        } else if let currentPage = currentPage as? UserMediaTimelineViewController {
            currentPage.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
        } else if let currentPage = currentPage as? UserLikeTimelineViewController {
            currentPage.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sender.endRefreshing()
        }
    }
    
    @objc private func floatyButtonPressed(_ sender: FloatyItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard let user = viewModel.user else { return }
        
        let composeViewModel = ComposeViewModel(context: context)
        let composeContentViewModel = ComposeContentViewModel(
            kind: {
                if user == viewModel.me {
                    return .post
                } else {
                    return .mention(user: user)
                }
            }(),
            configurationContext: ComposeContentViewModel.ConfigurationContext(
                apiService: context.apiService,
                authenticationService: context.authenticationService,
                mastodonEmojiService: context.mastodonEmojiService,
                statusViewConfigureContext: .init(
                    dateTimeProvider: DateTimeSwiftProvider(),
                    twitterTextProvider: OfficialTwitterTextProvider(),
                    authenticationContext: context.authenticationService.$activeAuthenticationContext
                )
            )
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel, contentViewModel: composeContentViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
}

// MARK: - AvatarBarButtonItemDelegate
extension ProfileViewController: AvatarBarButtonItemDelegate { }

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, friendshipButtonDidPressed button: UIButton) {
        guard let user = viewModel.user else { return }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return }
        guard let relationshipOptionSet = viewModel.relationshipViewModel.optionSet else { return }
        let record = UserRecord(object: user)

        Task {
            if relationshipOptionSet.contains(.blocking) {
                await DataSourceFacade.presentUserBlockAlert(
                    provider: self,
                    user: record,
                    authenticationContext: authenticationContext
                )
            } else {
                await DataSourceFacade.responseToFriendshipButtonAction(
                    provider: self,
                    user: record,
                    authenticationContext: authenticationContext
                )
            }
        }   // end Task { … }
    }
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        guard let user = viewModel.user else { return }
        let record = UserRecord(object: user)
        
        Task {
            await DataSourceFacade.responseToMetaTextAreaView(
                provider: self,
                user: record,
                didSelectMeta: meta
            )
        }
    }
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        guard let user = viewModel.user else { return }
        let record = UserRecord(object: user)
        
        Task {
            await DataSourceFacade.responseToMetaTextAreaView(
                provider: self,
                user: record,
                didSelectMeta: meta
            )
        }
    }
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        guard let userIdentifier = viewModel.userIdentifier else {
            assertionFailure()
            return
        }
        let friendshipListViewModel = FriendshipListViewModel(context: context, kind: .following, userIdentifier: userIdentifier)
        coordinator.present(scene: .friendshipList(viewModel: friendshipListViewModel), from: self, transition: .show)
    }
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        guard let userIdentifier = viewModel.userIdentifier else {
            assertionFailure()
            return
        }
        let friendshipListViewModel = FriendshipListViewModel(context: context, kind: .follower, userIdentifier: userIdentifier)
        coordinator.present(scene: .friendshipList(viewModel: friendshipListViewModel), from: self, transition: .show)
    }
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        guard let user = viewModel.userRecord else { return }
        switch user {
        case .twitter:      break
        case .mastodon:     return
        }
        
        let compositeListViewModel = CompositeListViewModel(
            context: context,
            kind: .listed(user)
        )
        coordinator.present(
            scene: .compositeList(viewModel: compositeListViewModel),
            from: presentingViewController,
            transition: .show
        )
    }
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: ScrollViewContainer, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)

    }
    
}

// MARK: - TabBarPagerDelegate
extension ProfileViewController: TabBarPagerDelegate {
    
    func tabBarMinimalHeight() -> CGFloat {
        return profilePagingViewController.settings.style.buttonBarHeight ?? 44
    }
    
    func resetPageContentOffset(_ tabBarPagerController: TabBarPagerController) {
        for viewController in profilePagingViewController.viewModel.viewControllers {
            viewController.pageScrollView.contentOffset = .zero
        }
    }
    
    func tabBarPagerController(_ tabBarPagerController: TabBarPagerController, didScroll scrollView: UIScrollView) {
        // elastically banner
        if scrollView.contentOffset.y < -scrollView.safeAreaInsets.top {
            let offset = scrollView.contentOffset.y - (-scrollView.safeAreaInsets.top)
            profileHeaderViewController.headerView.bannerImageViewTopLayoutConstraint.constant = offset
        } else {
            profileHeaderViewController.headerView.bannerImageViewTopLayoutConstraint.constant = 0
        }
    }
}

// MARK: - TabBarPagerDataSource
extension ProfileViewController: TabBarPagerDataSource {
    func headerViewController() -> UIViewController & TabBarPagerHeader {
        return profileHeaderViewController
    }
    
    func pageViewController() -> UIViewController & TabBarPageViewController {
        return profilePagingViewController
    }
}

// MARK: - IndicatorInfoProvider
extension UserTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.TextFormatting.capitalFloatLeft.image.withRenderingMode(.alwaysTemplate))
    }
}

// MARK: - IndicatorInfoProvider
extension UserMediaTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.ObjectTools.photo.image.withRenderingMode(.alwaysTemplate))
    }
}

// MARK: - IndicatorInfoProvider
extension UserLikeTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate))
    }
}

// MARK: - ScrollViewContainer
extension ProfileViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return tabBarPagerController.relayScrollView
    }
}
