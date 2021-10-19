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
import TabBarPager
import XLPagerTabStrip

// TODO: DrawerSidebarTransitionableViewController
final class ProfileViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "ProfileViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
//    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    
    let avatarBarButtonItem = AvatarBarButtonItem()
    let unmuteMenuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: Asset.ObjectTools.speakerXmark.image.withRenderingMode(.alwaysTemplate), style: .plain, target: nil, action: nil)
        barButtonItem.tintColor = .systemRed
        return barButtonItem
    }()
    let moreMenuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), style: .plain, target: nil, action: nil)
        barButtonItem.tintColor = Asset.Colors.hightLight.color
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
        viewModel.userIdentifier
            .assign(to: \.value, on: userTimelineViewModel.userIdentifier)
            .store(in: &disposeBag)
        
        let userMediaTimelineViewModel = UserMediaTimelineViewModel(context: context)
        viewModel.userIdentifier
            .assign(to: \.value, on: userMediaTimelineViewModel.userIdentifier)
            .store(in: &disposeBag)
        
        let userLikeTimelineViewModel = UserLikeTimelineViewModel(context: context)
        viewModel.userIdentifier
            .assign(to: \.value, on: userLikeTimelineViewModel.userIdentifier)
            .store(in: &disposeBag)
        
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
    
//    private(set) lazy var profileSegmentedViewController = ProfileSegmentedViewController()
    
//    private(set) lazy var bar: TMBar = {
//        let bar = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
//        bar.layout.contentMode = .fit
//        bar.indicator.weight = .custom(value: 2)
//        bar.backgroundView.style = .flat(color: .systemBackground)
//        bar.buttons.customize { barItem in
//            barItem.shrinksImageWhenUnselected = false
//            barItem.selectedTintColor = Asset.Colors.hightLight.color
//            barItem.tintColor = .secondaryLabel
//        }
//        return bar
//    }()
    
    private var contentOffsets: [Int: CGFloat] = [:]
    var currentPostTimelineTableViewContentSizeObservation: NSKeyValueObservation?
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = avatarBarButtonItem
        }
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(ProfileViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        
        unmuteMenuBarButtonItem.target = self
        unmuteMenuBarButtonItem.action = #selector(ProfileViewController.unmuteBarButtonItemPressed(_:))
        
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
        
        
//        Publishers.CombineLatest4(
//            viewModel.muted.eraseToAnyPublisher(),
//            viewModel.blocked.eraseToAnyPublisher(),
//            viewModel.twitterUser.eraseToAnyPublisher(),
//            context.authenticationService.activeTwitterAuthenticationBox.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] muted, blocked, twitterUser, activeTwitterAuthenticationBox in
//            guard let self = self else { return }
//            guard let twitterUser = twitterUser,
//                  let activeTwitterAuthenticationBox = activeTwitterAuthenticationBox,
//                  twitterUser.id != activeTwitterAuthenticationBox.twitterUserID else {
//                self.navigationItem.rightBarButtonItems = []
//                return
//            }
//
//            if #available(iOS 14.0, *) {
//                self.moreMenuBarButtonItem.target = nil
//                self.moreMenuBarButtonItem.action = nil
//                self.moreMenuBarButtonItem.menu = UserProviderFacade.createMenuForUser(
//                    twitterUser: twitterUser,
//                    muted: muted,
//                    blocked: blocked,
//                    dependency: self
//                )
//            } else {
//                // no menu supports for early version
//                self.moreMenuBarButtonItem.target = self
//                self.moreMenuBarButtonItem.action = #selector(ProfileViewController.moreMenuBarButtonItemPressed(_:))
//            }
//
//            var rightBarButtonItems: [UIBarButtonItem] = [self.moreMenuBarButtonItem]
//            if muted {
//                rightBarButtonItems.append(self.unmuteMenuBarButtonItem)
//            }
//
//            self.navigationItem.rightBarButtonItems = rightBarButtonItems
//        }
//        .store(in: &disposeBag)
        
        tabBarPagerController.relayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
//        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
        
//        let userTimelineViewModel = UserTimelineViewModel(context: context)
//        viewModel.userIdentifier
//            .assign(to: \.value, on: userTimelineViewModel.userIdentifier)
//            .store(in: &disposeBag)

//        let userMediaTimelineViewModel = UserMediaTimelineViewModel(context: context)
//        viewModel.userIdentifier
//            .assign(to: \.value, on: userMediaTimelineViewModel.userIdentifier)
//            .store(in: &disposeBag)

//        let userLikeTimelineViewModel = UserLikeTimelineViewModel(context: context)
//        viewModel.userIdentifier
//            .assign(to: \.value, on: userLikeTimelineViewModel.userIdentifier)
//            .store(in: &disposeBag)
        
//        profileSegmentedViewController.pagingViewController.viewModel = {
//            let profilePagingViewModel = ProfilePagingViewModel(
//                userTimelineViewModel: userTimelineViewModel,
//                userMediaTimelineViewModel: userMediaTimelineViewModel,
//                userLikeTimelineViewModel: userLikeTimelineViewModel
//            )
//            profilePagingViewModel.viewControllers.forEach { viewController in
//                if let viewController = viewController as? NeedsDependency {
//                    viewController.context = context
//                    viewController.coordinator = coordinator
//                }
//            }
//            return profilePagingViewModel
//        }()

//        overlayScrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(overlayScrollView)
//        NSLayoutConstraint.activate([
//            overlayScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
//            overlayScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.bottomAnchor),
//            overlayScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
//        ])
//
//        containerScrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(containerScrollView)
//        NSLayoutConstraint.activate([
//            containerScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
//            containerScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.bottomAnchor),
//            containerScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
//        ])
//
//        // add segmented list
//        addChild(profileSegmentedViewController)
//        profileSegmentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        containerScrollView.addSubview(profileSegmentedViewController.view)
//        profileSegmentedViewController.didMove(toParent: self)
//        NSLayoutConstraint.activate([
//            profileSegmentedViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
//            profileSegmentedViewController.view.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
//            profileSegmentedViewController.view.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),
//            profileSegmentedViewController.view.heightAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.heightAnchor),
//        ])
//
//        addChild(profileHeaderViewController)
//        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        containerScrollView.addSubview(profileHeaderViewController.view)
//        profileHeaderViewController.didMove(toParent: self)
//        NSLayoutConstraint.activate([
//            profileHeaderViewController.view.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
//            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
//            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: profileHeaderViewController.view.trailingAnchor),
//            profileSegmentedViewController.view.topAnchor.constraint(equalTo: profileHeaderViewController.view.bottomAnchor),
//        ])
//
//        containerScrollView.addGestureRecognizer(overlayScrollView.panGestureRecognizer)
//        overlayScrollView.layer.zPosition = .greatestFiniteMagnitude    // make vision top-most
//        overlayScrollView.delegate = self
//        profileHeaderViewController.delegate = self
//        profileSegmentedViewController.pagingViewController.pagingDelegate = self
//
//        // add segmented bar to header
//        profileSegmentedViewController.pagingViewController.addBar(
//            bar,
//            dataSource: profileSegmentedViewController.pagingViewController.viewModel,
//            at: .custom(view: profileHeaderViewController.view, layout: { bar in
//                bar.translatesAutoresizingMaskIntoConstraints = false
//                self.profileHeaderViewController.view.addSubview(bar)
//                NSLayoutConstraint.activate([
//                    bar.leadingAnchor.constraint(equalTo: self.profileHeaderViewController.view.leadingAnchor),
//                    bar.trailingAnchor.constraint(equalTo: self.profileHeaderViewController.view.trailingAnchor),
//                    bar.bottomAnchor.constraint(equalTo: self.profileHeaderViewController.view.bottomAnchor),
//                    bar.heightAnchor.constraint(equalToConstant: ProfileHeaderViewController.headerMinHeight).priority(.defaultHigh),
//                ])
//            })
//        )

        // bind view model
        viewModel.$user
            .assign(to: &profileHeaderViewController.viewModel.$user)
        viewModel.relationshipViewModel.$optionSet
            .map { $0?.relationship(except: [.muting]) }
            .assign(to: &profileHeaderViewController.viewModel.$relationship)
        
//        Publishers.CombineLatest3(
//            viewModel.bannerImageURL.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher(),
//            viewModel.viewDidAppear.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] url, isSuspended, _ in
//            guard let self = self else { return }
//            guard !isSuspended else {
//                self.profileHeaderViewController.profileBannerView.profileBannerImageView.image = UIImage.placeholder(color: .systemGray)
//                return
//            }
//            let placeholderImage = UIImage.placeholder(color: Asset.Colors.hightLight.color)
//            guard let url = url else {
//                self.profileHeaderViewController.profileBannerView.profileBannerImageView.image = placeholderImage
//                return
//            }
//            self.profileHeaderViewController.profileBannerView.profileBannerImageView.af.setImage(
//                withURL: url,
//                placeholderImage: placeholderImage,
//                imageTransition: .crossDissolve(0.3),
//                runImageTransitionIfCached: false,
//                completion: { [weak self] response in
//                    guard let self = self else { return }
//                    switch response.result {
//                    case .success(let image):
//                        if #available(iOS 14.0, *) {
//                            guard let inversedDominantColor = image.dominantColor?.complementary else { return }
//                            self.refreshControl.tintColor = inversedDominantColor
//                        }
//                    case .failure:
//                        break
//                    }
//                }
//            )
//        }
//        .store(in: &disposeBag)
//        let verifiedAndBlocked = Publishers.CombineLatest(
//            viewModel.verified.eraseToAnyPublisher(),
//            viewModel.blocked.eraseToAnyPublisher()
//        )
//        Publishers.CombineLatest4(
//            viewModel.avatarImageURL.eraseToAnyPublisher(),
//            verifiedAndBlocked.eraseToAnyPublisher(),
//            viewModel.avatarStyle.eraseToAnyPublisher(),
//            viewModel.viewDidAppear.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] avatarImageURL, verifiedAndblocked, _, _ in
//            guard let self = self else { return }
//            let (verified, blocked) = verifiedAndblocked
//            self.profileHeaderViewController.profileBannerView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL, blocked: blocked, verified: verified))
//        }
//        .store(in: &disposeBag)
//        viewModel.protected
//            .map { $0 != true }
//            .assign(to: \.isHidden, on: profileHeaderViewController.profileBannerView.lockImageView)
//            .store(in: &disposeBag)
//        viewModel.name
//            .map { $0 ?? " " }
//            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.nameLabel)
//            .store(in: &disposeBag)
//        viewModel.username
//            .map { username in username.flatMap { "@" + $0 } ?? " " }
//            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.usernameLabel)
//            .store(in: &disposeBag)
//        viewModel.friendship
//            .sink { [weak self] friendship in
//                guard let self = self else { return }
//                let followingButton = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followActionButton
//                followingButton.isHidden = friendship == nil
//
//                if let friendship = friendship {
//                    switch friendship {
//                    case .following:    followingButton.style = .following
//                    case .pending:      followingButton.style = .pending
//                    case .none:         followingButton.style = .follow
//                    }
//                }
//            }
//            .store(in: &disposeBag)
//        viewModel.followedBy
//            .sink { [weak self] followedBy in
//                guard let self = self else { return }
//                let followStatusLabel = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followStatusLabel
//                followStatusLabel.isHidden = followedBy != true
//            }
//            .store(in: &disposeBag)
//
//        Publishers.CombineLatest(
//            viewModel.bioDescription.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink(receiveValue: { [weak self] bio, isSuspended in
//            guard let self = self else { return }
//            self.profileHeaderViewController.profileBannerView.bioLabel.configure(with: bio ?? " ")
//            self.profileHeaderViewController.profileBannerView.bioLabel.isHidden = isSuspended
//        })
//        .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            viewModel.url.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] url, isSuspended in
//            guard let self = self else { return }
//            let url = url.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
//            self.profileHeaderViewController.profileBannerView.linkButton.setTitle(url, for: .normal)
//            let isEmpty = url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//            self.profileHeaderViewController.profileBannerView.linkContainer.isHidden = isEmpty || isSuspended
//        }
//        .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            viewModel.location.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] location, isSuspended in
//            guard let self = self else { return }
//            let location = location.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
//            self.profileHeaderViewController.profileBannerView.geoButton.setTitle(location, for: .normal)
//            let isEmpty = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//            self.profileHeaderViewController.profileBannerView.geoContainer.isHidden = isEmpty || isSuspended
//        }
//        .store(in: &disposeBag)
//        viewModel.friendsCount
//            .sink { [weak self] count in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followingStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
//            }
//            .store(in: &disposeBag)
//        viewModel.followersCount
//            .sink { [weak self] count in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followersStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
//            }
//            .store(in: &disposeBag)
//        viewModel.listedCount
//            .sink { [weak self] count in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.listedStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
//            }
//            .store(in: &disposeBag)
//        viewModel.suspended
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isSuspended in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.isHidden = isSuspended
//                self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.isHidden = isSuspended
//                if isSuspended {
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileTweetPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserTimelineViewModel.State.Suspended.self)
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileMediaPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserMediaTimelineViewModel.State.Suspended.self)
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileLikesPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserLikeTimelineViewModel.State.Suspended.self)
//                }
//            }
//            .store(in: &disposeBag)
//
//        Publishers.CombineLatest3(
//            context.authenticationService.activeAuthenticationIndex.eraseToAnyPublisher(),
//            viewModel.avatarStyle.eraseToAnyPublisher(),
//            viewModel.viewDidAppear.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] activeAuthenticationIndex, _, _ in
//            guard let self = self else { return }
//            guard let twitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser,
//                  let avatarImageURL = twitterUser.avatarImageURL() else {
//                self.avatarBarButtonItem.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: nil))
//                return
//            }
//            self.avatarBarButtonItem.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL))
//        }
//        .store(in: &disposeBag)
            
//        profileHeaderViewController.profileBannerView.profileBannerInfoActionView.delegate = self
//        profileHeaderViewController.profileBannerView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        viewModel.viewDidAppear.send()
        
        // set overlay scroll view initial content size
//        guard let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer else { return }
//        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: currentViewController.scrollView)
//        currentViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        currentPostTimelineTableViewContentSizeObservation = nil
    }
    
}

extension ProfileViewController {
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
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
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
    @objc private func unmuteBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let twitterUser = viewModel.twitterUser.value else {
//            assertionFailure()
//            return
//        }
//
//        UserProviderFacade.toggleMuteUser(
//            context: context,
//            twitterUser: twitterUser,
//            muted: viewModel.muted.value
//        )
//        .sink { _ in
//            // do nothing
//        } receiveValue: { _ in
//            // do nothing
//        }
//        .store(in: &disposeBag)
    }
    
    @objc private func moreMenuBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let twitterUser = viewModel.twitterUser.value else {
//            assertionFailure()
//            return
//        }
//
//        let moreMenuAlertController = UserProviderFacade.createMoreMenuAlertControllerForUser(
//            twitterUser: twitterUser,
//            muted: viewModel.muted.value,
//            blocked: viewModel.blocked.value,
//            sender: sender,
//            dependency: self
//        )
//        present(moreMenuAlertController, animated: true, completion: nil)
    }
    
}

// MARK: - UIScrollViewDelegate
//extension ProfileViewController: UIScrollViewDelegate {
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        // elastically banner
//        if overlayScrollView.contentOffset.y < -overlayScrollView.safeAreaInsets.top {
//            let offset = overlayScrollView.contentOffset.y - (-overlayScrollView.safeAreaInsets.top)
//            profileHeaderViewController.headerView.bannerImageViewTopLayoutConstraint.constant = offset
//        } else {
//            profileHeaderViewController.headerView.bannerImageViewTopLayoutConstraint.constant = 0
//        }
//
//        contentOffsets[profileSegmentedViewController.pagingViewController.currentIndex!] = scrollView.contentOffset.y
//
//        let topMaxContentOffsetY = profileSegmentedViewController.view.frame.minY - ProfileHeaderViewController.headerMinHeight - containerScrollView.safeAreaInsets.top
//        if scrollView.contentOffset.y < topMaxContentOffsetY {
//            self.containerScrollView.contentOffset.y = scrollView.contentOffset.y
//            for postTimelineView in profileSegmentedViewController.pagingViewController.viewModel.viewControllers {
//                postTimelineView.scrollView.contentOffset.y = 0
//            }
//            contentOffsets.removeAll()
//        } else {
//            containerScrollView.contentOffset.y = topMaxContentOffsetY
//            if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer {
//                let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
//                customScrollViewContainerController.scrollView.contentOffset.y = contentOffsetY
//            }
//        }
//    }
//
//}

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    func headerViewController(
        _ viewController: ProfileHeaderViewController,
        profileHeaderView: ProfileHeaderView, friendshipButtonDidPressed
        button: UIButton
    ) {
        guard let user = viewModel.user else { return }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
        let record = UserRecord(object: user)
        
        Task {
            await DataSourceFacade.responseToFriendshipButtonAction(
                provider: self,
                user: record,
                authenticationContext: authenticationContext
            )
        }
            
        //        UserProviderFacade
        //            .toggleUserFriendship(provider: self, sender: button)
        //            .sink { _ in
        //                // do nothing
        //            } receiveValue: { _ in
        //                // do nothing
        //            }
        //            .store(in: &disposeBag)
    }
    
//    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView) {
//        guard let scrollView = (profileSegmentedViewController.pagingViewController.currentViewController as? UserTimelineViewController)?.scrollView else {
//            // assertionFailure()
//            return
//        }
//
//        updateOverlayScrollViewContentSize(scrollView: scrollView)
//    }
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: ScrollViewContainer, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        
//        // save content offset
//        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
//        
//        // setup observer and gesture fallback
//        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: postTimelineViewController.scrollView)
//        postTimelineViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
        
        
//        if let userMediaTimelineViewController = postTimelineViewController as? UserMediaTimelineViewController,
//           let currentState = userMediaTimelineViewController.viewModel.stateMachine.currentState {
//            switch currentState {
//            case is UserMediaTimelineViewModel.State.NoMore,
//                 is UserMediaTimelineViewModel.State.NotAuthorized,
//                 is UserMediaTimelineViewModel.State.Blocked:
//                break
//            default:
//                if userMediaTimelineViewController.viewModel.items.value.isEmpty {
//                    userMediaTimelineViewController.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
//                }
//            }
//        }
//        
//        if let userLikeTimelineViewController = postTimelineViewController as? UserLikeTimelineViewController,
//           let currentState = userLikeTimelineViewController.viewModel.stateMachine.currentState {
//            switch currentState {
//            case is UserLikeTimelineViewModel.State.NoMore,
//                 is UserLikeTimelineViewModel.State.NotAuthorized,
//                 is UserLikeTimelineViewModel.State.Blocked:
//                break
//            default:
//                if userLikeTimelineViewController.viewModel.items.value.isEmpty {
//                    userLikeTimelineViewController.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
//                }
//            }
//        }
    }
    
}

// MARK: - ProfileBannerViewDelegate
//extension ProfileViewController: ProfileBannerViewDelegate {
//
//    func profileBannerView(_ profileBannerView: ProfileBannerView, linkButtonDidPressed button: UIButton) {
//        guard let urlString = viewModel.url.value, let url = URL(string: urlString) else { return }
//        coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
//    }
//
//    func profileBannerView(_ profileBannerView: ProfileBannerView, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
//        switch entity.type {
//        case .hashtag(let text):
//            let searchDetailViewModel = SearchDetailViewModel(initialSearchText: "#" + text)
//            coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .show)
//        case .mention(let text):
//            let profileViewModel: ProfileViewModel = {
//                let targetUsername = text
//                let targetUser: TwitterUser? = {
//                    let userRequest = TwitterUser.sortedFetchRequest
//                    userRequest.fetchLimit = 1
//                    userRequest.predicate = TwitterUser.predicate(username: targetUsername)
//                    do {
//                        return try self.context.managedObjectContext.fetch(userRequest).first
//                    } catch {
//                        assertionFailure(error.localizedDescription)
//                        return nil
//                    }
//                }()
//
//                if let targetUser = targetUser {
//                    let activeAuthenticationIndex = self.context.authenticationService.activeAuthenticationIndex.value
//                    let currentTwitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser
//                    if targetUser.id == currentTwitterUser?.id {
//                        return MeProfileViewModel(context: self.context)
//                    } else {
//                        return ProfileViewModel(context: self.context, twitterUser: targetUser)
//                    }
//                } else {
//                    return ProfileViewModel(context: self.context, username: targetUsername)
//                }
//            }()
//
//            DispatchQueue.main.async {
//                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//            }
//        case .url(let originalURL, _):
//            guard let url = URL(string: originalURL) else { return }
//            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
//        default:
//            break
//        }
//    }
//
//    func profileBannerView(_ profileBannerView: ProfileBannerView, profileBannerStatusView: ProfileBannerStatusView, followingStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
//        guard let twitterUserID = viewModel.twitterUser.value?.id else { return }
//        let followingListViewModel = FriendshipListViewModel(context: context, userID: twitterUserID, friendshipLookupKind: .following)
//        self.coordinator.present(scene: .friendshipList(viewModel: followingListViewModel), from: nil, transition: .show)
//    }
//
//    func profileBannerView(_ profileBannerView: ProfileBannerView, profileBannerStatusView: ProfileBannerStatusView, followerStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
//        guard let twitterUserID = viewModel.twitterUser.value?.id else { return }
//        let followingListViewModel = FriendshipListViewModel(context: context, userID: twitterUserID, friendshipLookupKind: .followers)
//        self.coordinator.present(scene: .friendshipList(viewModel: followingListViewModel), from: nil, transition: .show)
//    }
//
//    func profileBannerView(_ profileBannerView: ProfileBannerView, profileBannerStatusView: ProfileBannerStatusView, listedStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
//        // TODO:
//    }
//
//
//}


//// MARK: - ScrollViewContainer
//extension ProfileViewController: ScrollViewContainer {
//    var scrollView: UIScrollView { return overlayScrollView }
//}

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

extension UserTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.TextFormatting.capitalFloatLeft.image.withRenderingMode(.alwaysTemplate))
    }
}

extension UserMediaTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.ObjectTools.photo.image.withRenderingMode(.alwaysTemplate))
    }
}

extension UserLikeTimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(image: Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate))
    }
}
