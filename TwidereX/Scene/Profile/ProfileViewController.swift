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
import Tabman
import AlamofireImage
import Kingfisher
import ActiveLabel

final class ProfileViewController: UIViewController, DrawerSidebarTransitionableViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    
    let avatarButton = UIButton.avatarButton
    
    let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        return refreshControl
    }()
    
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
        
        overlayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
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
        overlayScrollView.layer.zPosition = .greatestFiniteMagnitude    // make vision top-most
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
        Publishers.CombineLatest(
            viewModel.bannerImageURL.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] url, _ in
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
                completion: { [weak self] response in
                    guard let self = self else { return }
                    switch response.result {
                    case .success(let image):
                        if #available(iOS 14.0, *) {
                            guard let inversedDominantColor = image.dominantColor?.complementary else { return }
                            self.refreshControl.tintColor = inversedDominantColor
                        }
                    case .failure:
                        break
                    }
                }
            )
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            viewModel.avatarImageURL.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] url, _ in
            guard let self = self else { return }
            guard let url = url else { return }
            self.profileHeaderViewController.profileBannerView.profileAvatarImageView.af.cancelImageRequest()
            self.profileHeaderViewController.profileBannerView.profileAvatarImageView.kf.cancelDownloadTask()
            
            let placeholderImage = UIImage
                .placeholder(size: ProfileBannerView.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            if url.pathExtension == "gif" {
                self.profileHeaderViewController.profileBannerView.profileAvatarImageView.kf.setImage(
                    with: url,
                    placeholder: placeholderImage,
                    options: [
                        .processor(
                            CroppingImageProcessor(size: ProfileBannerView.avatarImageViewSize, anchor: CGPoint(x: 0.5, y: 0.5)) |>
                            RoundCornerImageProcessor(cornerRadius: 0.5 * ProfileBannerView.avatarImageViewSize.width)
                        ),
                        .transition(.fade(0.2))
                    ]
                )
            } else {
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
                followingButton.isHidden = friendship == nil

                if let friendship = friendship {
                    switch friendship {
                    case .following:    followingButton.style = .following
                    case .pending:      followingButton.style = .pending
                    case .none:         followingButton.style = .follow
                    }
                }
            }
            .store(in: &disposeBag)
        viewModel.bioDescription
            .map { $0 ?? " " }
            .sink(receiveValue: { [weak self] bio in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.bioLabel.configure(with: bio)
            })
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
        
        Publishers.CombineLatest(
            viewModel.currentTwitterUser.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] twitterUser, _ in
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
                self.profileHeaderViewController.profileBannerView.nameLabel.font = .preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
                self.profileHeaderViewController.profileBannerView.usernameLabel.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
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
        profileHeaderViewController.profileBannerView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
        
        // set overlay scroll view initial content size
        guard let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer else { return }
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: currentViewController.scrollView)
        currentViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentPostTimelineTableViewContentSizeObservation = nil
    }
    
}

extension ProfileViewController {
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController
        if let currentViewController = currentViewController as? UserTimelineViewController {
            currentViewController.viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
        } else if let currentViewController = currentViewController as? UserMediaTimelineViewController {
            currentViewController.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
        } else if let currentViewController = currentViewController as? UserLikeTimelineViewController {
            currentViewController.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sender.endRefreshing()            
        }
    }
    
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
            if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer {
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
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: ScrollViewContainer, atIndex index: Int) {
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
            let message = isPending ? L10n.Common.Alerts.CancelFollowRequest.message(name) : L10n.Common.Alerts.UnfollowUser.message(name)
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: view.traitCollection.userInterfaceIdiom == .phone ? .actionSheet : .alert)
            let confirmAction = UIAlertAction(title: L10n.Common.Controls.Actions.confirm, style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.toggleFollowStatue()
            }
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
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

// MARK: - ProfileBannerViewDelegate
extension ProfileViewController: ProfileBannerViewDelegate {
    
    func profileBannerView(_ profileBannerView: ProfileBannerView, linkButtonDidPressed button: UIButton) {
        guard let urlString = viewModel.url.value, let url = URL(string: urlString) else { return }
        coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
    }
    
    func profileBannerView(_ profileBannerView: ProfileBannerView, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        switch entity.type {
        case .mention(let text):
            let profileViewModel: ProfileViewModel = {
                let targetUsername = text
                let targetUser: TwitterUser? = {
                    let userRequest = TwitterUser.sortedFetchRequest
                    userRequest.fetchLimit = 1
                    userRequest.predicate = TwitterUser.predicate(username: targetUsername)
                    do {
                        return try self.context.managedObjectContext.fetch(userRequest).first
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return nil
                    }
                }()
                
                if let targetUser = targetUser {
                    let activeAuthenticationIndex = self.context.authenticationService.activeAuthenticationIndex.value
                    let currentTwitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser
                    if targetUser.id == currentTwitterUser?.id {
                        return MeProfileViewModel(activeAuthenticationIndex: activeAuthenticationIndex)
                    } else {
                        return ProfileViewModel(twitterUser: targetUser)
                    }
                } else {
                    return ProfileViewModel(context: self.context, username: targetUsername)
                }
            }()
            self.context.authenticationService.activeAuthenticationIndex
                .map { $0?.twitterAuthentication?.twitterUser }
                .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                .store(in: &profileViewModel.disposeBag)
            
            DispatchQueue.main.async {
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        case .url(let originalURL, _):
            guard let url = URL(string: originalURL) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
    
}


// MARK: - ScrollViewContainer
extension ProfileViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return overlayScrollView }
}
