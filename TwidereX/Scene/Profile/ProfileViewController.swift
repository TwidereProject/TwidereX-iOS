//
//  ProfileViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import Tabman
import AlamofireImage

final class ProfileViewController: UIViewController, DrawerSidebarTransitionableViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    
    let avatarButton = UIButton.avatarButton
    
    let containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.delaysContentTouches = false
        return scrollView
    }()
    let overlayScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.delaysContentTouches = false
        return scrollView
    }()
    lazy var profileSegmentedViewController = ProfileSegmentedViewController()
    lazy var profileHeaderViewController = ProfileHeaderViewController()
    
    lazy var bar: TMBar = {
        let bar = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        bar.layout.contentMode = .fit
        bar.indicator.weight = .custom(value: 2)
        bar.backgroundView.style = .flat(color: .systemBackground)
        bar.buttons.customize { barItem in
            barItem.shrinksImageWhenUnselected = false
            barItem.selectedTintColor = Asset.Colors.hightLight.color
            barItem.tintColor = .secondaryLabel
        }
        return bar
    }()
    
    private var contentOffsets: [Int: CGFloat] = [:]
    var currentPostTimelineTableViewContentSizeObservation: NSKeyValueObservation?
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ProfileViewController {
    
    func observeTableViewContentSize(scrollView: UIScrollView) -> NSKeyValueObservation {
        updateOverlayScrollViewContentSize(scrollView: scrollView)
        return scrollView.observe(\.contentSize, options: .new) { scrollView, change in
            self.updateOverlayScrollViewContentSize(scrollView: scrollView)
        }
    }
    
    func updateOverlayScrollViewContentSize(scrollView: UIScrollView) {
        let bottomPageHeight = max(scrollView.contentSize.height, self.containerScrollView.frame.height - ProfileHeaderViewController.headerMinHeight - self.containerScrollView.safeAreaInsets.bottom)
        let headerViewHeight: CGFloat = profileHeaderViewController.view.frame.height
        let contentSize = CGSize(
            width: self.containerScrollView.contentSize.width,
            height: bottomPageHeight + headerViewHeight
        )
        self.overlayScrollView.contentSize = contentSize
    }
    
}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avatarButton)
        }
        avatarButton.addTarget(self, action: #selector(ProfileViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
        
        let userTimelineViewModel = UserTimelineViewModel(context: context, userID: viewModel.userID.value)
        viewModel.userID.assign(to: \.value, on: userTimelineViewModel.userID).store(in: &disposeBag)
        
        let userMediaTimelineViewModel = UserMediaTimelineViewModel(context: context, userID: viewModel.userID.value)
        viewModel.userID.assign(to: \.value, on: userMediaTimelineViewModel.userID).store(in: &disposeBag)
        
        let userLikeTimelineViewModel = UserLikeTimelineViewModel(context: context, userID: viewModel.userID.value)
        viewModel.userID.assign(to: \.value, on: userLikeTimelineViewModel.userID).store(in: &disposeBag)
        
        profileSegmentedViewController.pagingViewController.viewModel = {
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

        overlayScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayScrollView)
        NSLayoutConstraint.activate([
            overlayScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            overlayScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.bottomAnchor),
            overlayScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        containerScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerScrollView)
        NSLayoutConstraint.activate([
            containerScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            containerScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.bottomAnchor),
            containerScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        // add segmented list
        addChild(profileSegmentedViewController)
        profileSegmentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(profileSegmentedViewController.view)
        profileSegmentedViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileSegmentedViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            profileSegmentedViewController.view.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
            profileSegmentedViewController.view.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),
            profileSegmentedViewController.view.heightAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.heightAnchor),
        ])

        addChild(profileHeaderViewController)
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(profileHeaderViewController.view)
        profileHeaderViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileHeaderViewController.view.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: profileHeaderViewController.view.trailingAnchor),
            profileSegmentedViewController.view.topAnchor.constraint(equalTo: profileHeaderViewController.view.bottomAnchor),
        ])

        containerScrollView.addGestureRecognizer(overlayScrollView.panGestureRecognizer)
        overlayScrollView.delegate = self
        profileHeaderViewController.delegate = self
        profileSegmentedViewController.pagingViewController.pagingDelegate = self

        // add segmented bar to header
        profileSegmentedViewController.pagingViewController.addBar(
            bar,
            dataSource: profileSegmentedViewController.pagingViewController.viewModel,
            at: .custom(view: profileHeaderViewController.view, layout: { bar in
                bar.translatesAutoresizingMaskIntoConstraints = false
                self.profileHeaderViewController.view.addSubview(bar)
                NSLayoutConstraint.activate([
                    bar.leadingAnchor.constraint(equalTo: self.profileHeaderViewController.view.leadingAnchor),
                    bar.trailingAnchor.constraint(equalTo: self.profileHeaderViewController.view.trailingAnchor),
                    bar.bottomAnchor.constraint(equalTo: self.profileHeaderViewController.view.bottomAnchor),
                    bar.heightAnchor.constraint(equalToConstant: ProfileHeaderViewController.headerMinHeight).priority(.defaultHigh),
                ])
            })
        )

        // setup view model
        viewModel.bannerImageURL
            .sink { [weak self] url in
                guard let self = self else { return }
                let placeholderImage = UIImage.placeholder(color: Asset.Colors.hightLight.color)
                guard let url = url else {
                    self.profileHeaderViewController.profileBannerView.profileBannerImageView.image = placeholderImage
                    return
                }
                self.profileHeaderViewController.profileBannerView.profileBannerImageView.af.setImage(
                    withURL: url,
                    placeholderImage: placeholderImage,
                    imageTransition: .crossDissolve(0.3),
                    runImageTransitionIfCached: false,
                    completion: nil
                )
            }
            .store(in: &disposeBag)
        viewModel.avatarImageURL
            .sink { [weak self] url in
                guard let self = self else { return }
                guard let url = url else { return }
                let placeholderImage = UIImage
                    .placeholder(size: ProfileBannerView.avatarImageViewSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                let filter = ScaledToSizeCircleFilter(size: ProfileBannerView.avatarImageViewSize)
                self.profileHeaderViewController.profileBannerView.profileAvatarImageView.af.setImage(
                    withURL: url,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.3),
                    runImageTransitionIfCached: false,
                    completion: nil
                )
            }
            .store(in: &disposeBag)
        viewModel.protected
            .map { $0 != true }
            .assign(to: \.isHidden, on: profileHeaderViewController.profileBannerView.lockImageView)
            .store(in: &disposeBag)
        viewModel.verified
            .map { $0 != true }
            .assign(to: \.isHidden, on: profileHeaderViewController.profileBannerView.verifiedBadgeImageView)
            .store(in: &disposeBag)
        viewModel.name
            .map { $0 ?? " " }
            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.nameLabel)
            .store(in: &disposeBag)
        viewModel.username
            .map { username in username.flatMap { "@" + $0 } ?? " " }
            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.usernameLabel)
            .store(in: &disposeBag)
        viewModel.friendship
            .sink { [weak self] friendship in
                guard let self = self else { return }
                let followingButton = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followActionButton

                guard let friendship = friendship else {
                    followingButton.isHidden = true
                    return
                }
                switch friendship {
                case .following:    followingButton.style = .following
                case .pending:      followingButton.style = .pending
                case .none:         followingButton.style = .follow
                }
            }
            .store(in: &disposeBag)
        viewModel.bioDescription
            .map { $0 ?? " " }
            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.bioLabel)
            .store(in: &disposeBag)
        viewModel.url
            .sink { [weak self] url in
                guard let self = self else { return }
                let url = url.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
                self.profileHeaderViewController.profileBannerView.linkButton.setTitle(url, for: .normal)
                let isEmpty = url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                self.profileHeaderViewController.profileBannerView.linkContainer.isHidden = isEmpty
            }
            .store(in: &disposeBag)
        viewModel.location
            .sink { [weak self] location in
                guard let self = self else { return }
                let location = location.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
                self.profileHeaderViewController.profileBannerView.geoButton.setTitle(location, for: .normal)
                let isEmpty = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                self.profileHeaderViewController.profileBannerView.geoContainer.isHidden = isEmpty
            }
            .store(in: &disposeBag)
        viewModel.friendsCount
            .sink { [weak self] count in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followingStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
            }
            .store(in: &disposeBag)
        viewModel.followersCount
            .sink { [weak self] count in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followersStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
            }
            .store(in: &disposeBag)
        viewModel.listedCount
            .sink { [weak self] count in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.listedStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
            }
            .store(in: &disposeBag)
        
        viewModel.currentTwitterUser
            .sink { [weak self] twitterUser in
                guard let self = self else { return }
                let placeholderImage = UIImage
                    .placeholder(size: UIButton.avatarButtonSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                guard let twitterUser = twitterUser, let avatarImageURL = twitterUser.avatarImageURL() else {
                    self.avatarButton.setImage(placeholderImage, for: .normal)
                    return
                }
                let filter = ScaledToSizeCircleFilter(size: UIButton.avatarButtonSize)
                self.avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter
                )
            }
            .store(in: &disposeBag)

        context.overrideTraitCollection
            .sink { [weak self] traitCollection in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.nameLabel.font = .preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.usernameLabel.font = .preferredFont(forTextStyle: .title2, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.bioLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.linkButton.titleLabel?.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.geoButton.titleLabel?.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followingStatusItemView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followingStatusItemView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followersStatusItemView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followersStatusItemView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.listedStatusItemView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.listedStatusItemView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
            }
            .store(in: &disposeBag)
            
        profileHeaderViewController.profileBannerView.profileBannerInfoActionView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set overlay scroll view initial content size
        guard let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as? CustomScrollViewContainerController else { return }
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: currentViewController.scrollView)
        currentViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentPostTimelineTableViewContentSizeObservation = nil
    }
    
}

extension ProfileViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
}

// MARK: - UIScrollViewDelegate
extension ProfileViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // elastically banner
        if overlayScrollView.contentOffset.y < -overlayScrollView.safeAreaInsets.top {
            let offset = overlayScrollView.contentOffset.y - (-overlayScrollView.safeAreaInsets.top)
            profileHeaderViewController.profileBannerView.profileBannerImageViewTopLayoutConstraint.constant = offset
        } else {
            profileHeaderViewController.profileBannerView.profileBannerImageViewTopLayoutConstraint.constant = 0
        }
        
        contentOffsets[profileSegmentedViewController.pagingViewController.currentIndex!] = scrollView.contentOffset.y
        
        let topMaxContentOffsetY = profileSegmentedViewController.view.frame.minY - ProfileHeaderViewController.headerMinHeight - containerScrollView.safeAreaInsets.top
        if scrollView.contentOffset.y < topMaxContentOffsetY {
            self.containerScrollView.contentOffset.y = scrollView.contentOffset.y
            for postTimelineView in profileSegmentedViewController.pagingViewController.viewModel.viewControllers {
                postTimelineView.scrollView.contentOffset.y = 0
            }
            contentOffsets.removeAll()
        } else {
            containerScrollView.contentOffset.y = topMaxContentOffsetY
            if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? CustomScrollViewContainerController {
                let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                customScrollViewContainerController.scrollView.contentOffset.y = contentOffsetY
            }
        }
    }

}

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView) {
        guard let scrollView = (profileSegmentedViewController.pagingViewController.currentViewController as? UserTimelineViewController)?.scrollView else {
            // assertionFailure()
            return
        }
        
        updateOverlayScrollViewContentSize(scrollView: scrollView)
    }
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: CustomScrollViewContainerController, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        
        // save content offset
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        // setup observer and gesture fallback
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: postTimelineViewController.scrollView)
        postTimelineViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
        
        
        if let userMediaTimelineViewController = postTimelineViewController as? UserMediaTimelineViewController, userMediaTimelineViewController.viewModel.items.value.isEmpty {
            userMediaTimelineViewController.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
        }
        
        if let userLikeTimelineViewController = postTimelineViewController as? UserLikeTimelineViewController, userLikeTimelineViewController.viewModel.items.value.isEmpty {
            userLikeTimelineViewController.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
        }
    }
    
}

// MARK: - ProfileBannerInfoActionViewDelegate
extension ProfileViewController: ProfileBannerInfoActionViewDelegate {
    
    func profileBannerInfoActionView(_ profileBannerInfoActionView: ProfileBannerInfoActionView, followActionButtonPressed button: FollowActionButton) {
        guard let twitterUser = viewModel.twitterUser.value,
              let currentTwitterUser = viewModel.currentTwitterUser.value else { return }
        let requestTwitterUserID = currentTwitterUser.id
        
        let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
        let isFollowing = (twitterUser.followingFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
        
        if isPending || isFollowing {
            let name = twitterUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = isPending ? "Cancel following request for \(name)?" : "Unfollow user \(name)?"
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: view.traitCollection.userInterfaceIdiom == .phone ? .actionSheet : .alert)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.toggleFollowStatue()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            toggleFollowStatue()
        }
        
    }
    
    private func toggleFollowStatue() {
        guard let twitterUser = viewModel.twitterUser.value else {
            return
        }
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        context.apiService.friendship(
            twitterUserObjectID: twitterUser.objectID,
            twitterAuthenticationBox: activeTwitterAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            notificationFeedbackGenerator.prepare()
            impactFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            impactFeedbackGenerator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                break
            case .finished:
                // auto-reload item
                break
            }
        }
        .map { (friendshipQueryType, targetTwitterUserID) in
            self.context.apiService.friendship(
                friendshipQueryType: friendshipQueryType,
                twitterUserID: targetTwitterUserID,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            if self.view.window != nil {
                notificationFeedbackGenerator.notificationOccurred(.success)
            }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship query fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship query success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            
        }
        .store(in: &disposeBag)
    }
    
}
