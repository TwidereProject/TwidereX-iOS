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

final class ProfileViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
        
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
    
    func observeTableViewContentSize(tableView: UITableView) -> NSKeyValueObservation {
        updateOverlayScrollViewContentSize(tableView: tableView)
        return tableView.observe(\.contentSize, options: .new) { tableView, change in
            self.updateOverlayScrollViewContentSize(tableView: tableView)
        }
    }
    
    func updateOverlayScrollViewContentSize(tableView: UITableView) {
        let bottomPageHeight = max(tableView.contentSize.height, self.containerScrollView.frame.height - ProfileHeaderViewController.headerMinHeight - self.containerScrollView.safeAreaInsets.bottom)
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

        let userTimelineViewModel = UserTimelineViewModel(context: context, userID: viewModel.userID.value)
        viewModel.userID.assign(to: \.value, on: userTimelineViewModel.userID).store(in: &disposeBag)
        let profilePagingViewModel = ProfilePagingViewModel(userTimelineViewModel: userTimelineViewModel)
        profilePagingViewModel.viewControllers.forEach { viewController in
            if let viewController = viewController as? NeedsDependency {
                viewController.context = context
                viewController.coordinator = coordinator
            }
//            viewController.view.preservesSuperviewLayoutMargins = true
//            viewController.view.insetsLayoutMarginsFromSafeArea = true
        }

        profileSegmentedViewController.pagingViewController.viewModel = profilePagingViewModel

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
                guard let url = url else { return }
                self.profileHeaderViewController.profileBannerView.profileBannerImageView.af.setImage(
                    withURL: url,
                    placeholderImage: UIImage.placeholder(color: Asset.Colors.hightLight.color),
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
                self.profileHeaderViewController.profileBannerView.profileAvatarImageView.af.setImage(
                    withURL: url,
                    placeholderImage: UIImage.placeholder(color: .secondarySystemBackground),
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
        viewModel.isFolling
            .sink { [weak self] isFolling in
                guard let self = self else { return }
                let followingButton = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followActionButton
                let title = isFolling == true ? "Following" : "Follow"
                followingButton.setTitle(title, for: .normal)
                followingButton.setTitleColor(isFolling == true ? .white : Asset.Colors.hightLight.color, for: .normal)
                followingButton.setTitleColor(isFolling == true ? .white : Asset.Colors.hightLight.color, for: .highlighted)
                followingButton.setBackgroundImage(isFolling == true ? UIImage.placeholder(color: Asset.Colors.hightLight.color) : nil, for: .normal)
                followingButton.setBackgroundImage(isFolling == true ? UIImage.placeholder(color: Asset.Colors.hightLight.color.withAlphaComponent(0.5)) : nil, for: .highlighted)
                followingButton.layer.borderWidth = isFolling == true ? 0 : 1
                followingButton.isEnabled = isFolling != nil
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set overlay scroll view initial content size
        let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as! UserTimelineViewController
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(tableView: currentViewController.tableView)
        currentViewController.tableView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentPostTimelineTableViewContentSizeObservation = nil
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
                postTimelineView.tableView.contentOffset.y = 0
            }
            contentOffsets.removeAll()
        } else {
            containerScrollView.contentOffset.y = topMaxContentOffsetY
            if let userTimelineViewController = profileSegmentedViewController.pagingViewController.currentViewController as? UserTimelineViewController {
                let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                userTimelineViewController.tableView.contentOffset.y = contentOffsetY
            }
        }
    }

}

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView) {
        guard let tableView = (profileSegmentedViewController.pagingViewController.currentViewController as? UserTimelineViewController)?.tableView else {
            assertionFailure()
            return
        }
        
        updateOverlayScrollViewContentSize(tableView: tableView)
    }
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostTimelineViewController postTimelineViewController: CustomTableViewController, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        
        // save content offset
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        // setup observer and gesture fallback
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(tableView: postTimelineViewController.tableView)
        postTimelineViewController.tableView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
}
