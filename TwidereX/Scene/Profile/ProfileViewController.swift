//
//  ProfileViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Combine
import Tabman

final class ProfileViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    //var viewModel: TweetPostViewModel!

    let containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    let overlayScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    lazy var profileSegmentedViewController = ProfileSegmentedViewController()
    lazy var profileHeaderViewController = ProfileHeaderViewController()
    
    lazy var bar: TMBar = {
        let bar = TMBar.ButtonBar()
        bar.layout.transitionStyle = .snap
        bar.layout.contentMode = .fit
        bar.backgroundView.style = .clear
        bar.backgroundColor = .systemBackground
        return bar
    }()
    
    private var contentOffsets: [Int: CGFloat] = [:]
    var currentPostTimelineTableViewContentSizeObservation: NSKeyValueObservation?

}

extension ProfileViewController {
    
    func observeTableViewContentSize(tableView: UITableView) -> NSKeyValueObservation {
        updateOverlayScrollViewContentSize(tableView: tableView)
        return tableView.observe(\.contentSize, options: .new) { tableView, change in
            self.updateOverlayScrollViewContentSize(tableView: tableView)
        }
    }
    
    func updateOverlayScrollViewContentSize(tableView: UITableView) {
        let bottomHeight = max(tableView.contentSize.height, self.containerScrollView.frame.height - ProfileHeaderViewController.headerMinHeight - self.containerScrollView.safeAreaInsets.bottom)
        let headerViewHeight: CGFloat = profileHeaderViewController.view.frame.height
        let contentSize = CGSize(
            width: self.containerScrollView.contentSize.width,
            height: bottomHeight + headerViewHeight
        )
        self.overlayScrollView.contentSize = contentSize
    }
    
}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Me"
        view.backgroundColor = .systemBackground
        
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
        
        let testView = UIView()
        testView.backgroundColor = .yellow
        testView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testView)
        NSLayoutConstraint.activate([
            testView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            testView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            testView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            testView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set overlay scroll view initial content size
        let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as! ProfilePostTimelineViewController
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(tableView: currentViewController.tableView)
        currentViewController.tableView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
}

// MARK: - UIScrollViewDelegate
extension ProfileViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
            (profileSegmentedViewController.pagingViewController.currentViewController as? ProfilePostTimelineViewController)?.tableView.contentOffset.y = scrollView.contentOffset.y - containerScrollView.contentOffset.y
        }
    }

}

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView) {
        guard let tableView = (profileSegmentedViewController.pagingViewController.currentViewController as? ProfilePostTimelineViewController)?.tableView else {
            assertionFailure()
            return
        }
        
        updateOverlayScrollViewContentSize(tableView: tableView)
    }
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {
    
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostTimelineViewController postTimelineViewController: ProfilePostTimelineViewController, atIndex index: Int) {
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(tableView: postTimelineViewController.tableView)
        postTimelineViewController.tableView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }
    
}
