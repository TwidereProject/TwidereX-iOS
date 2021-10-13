//
//  TabBarPagerController.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import os.log
import UIKit
import Tabman
import Pageboy

public protocol TabBarPagerDelegate: AnyObject {
    func tabBar() -> TMBar
    func tabBarDataSource() -> TMBarDataSource
    func resetPageContentOffset(_ tabBarPagerController: TabBarPagerController)
    func tabBarPagerController(_ tabBarPagerController: TabBarPagerController, didScroll scrollView: UIScrollView)
}

public class TabBarPagerController: UIViewController {
    
    let logger = Logger(subsystem: "TabBarPagerController", category: "UI")
    
    // The container scrollView for display content
    public let containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.delaysContentTouches = false
        scrollView.accessibilityLabel = "ContainerScrollView"
        return scrollView
    }()
    
    // The relay scrollView for user interaction
    //
    // 1. pan gesture will be drop in this trap
    // 2. scrollViewDidScroll(_:) will relay content offset changes to `containerScrollView` and
    //    fire the `TabBarPagerControllerDelegate` method
    public let relayScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.delaysContentTouches = false
        scrollView.accessibilityLabel = "GestureRelayScrollView"
        return scrollView
    }()
    
    private var contentOffsets: [PageIndex: CGFloat] = [:]
    private var contentSizeObservations: [PageIndex: NSKeyValueObservation] = [:]
    
    public weak var delegate: TabBarPagerDelegate?
    public weak var dataSource: TabBarPagerDataSource? {
        didSet { layout() }
    }
    
}

extension TabBarPagerController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    
        relayScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(relayScrollView)
        NSLayoutConstraint.activate([
            relayScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            relayScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: relayScrollView.frameLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: relayScrollView.frameLayoutGuide.bottomAnchor),
            relayScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
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
        
        containerScrollView.addGestureRecognizer(relayScrollView.panGestureRecognizer)
        relayScrollView.layer.zPosition = .greatestFiniteMagnitude    // make pan gesture deliver first
        relayScrollView.delegate = self
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        updatePageObservation()
    }
    
}

extension TabBarPagerController {
    private func layout() {
        guard let dataSource = self.dataSource else { return }
        guard let delegate = self.delegate else {
            assertionFailure("please set delegate before dataSource")
            return
        }
        let pageViewController = dataSource.pageViewController()
        let headerViewController = dataSource.headerViewController()
        
        // With [Top] and [Bottom] layout constraint.
        // The container content height will be:
        // height = headerViewController.height + pageViewController.view.height
        
        // add pageboyViewController
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),   // constraint container content bottom layout to page view bottom [Bottom]
            pageViewController.view.heightAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.heightAnchor),     // constraint page view same height to container *frame* height
        ])
        
        // add headerViewController
        addChild(headerViewController)
        headerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(headerViewController.view)
        headerViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            headerViewController.view.topAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.topAnchor),          // constraint container content top layout to header view top [Top]
            headerViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: headerViewController.view.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: headerViewController.view.bottomAnchor),                      // constraint page view below header
        ])
        
        
        // add segmented bar to header
        let bar = delegate.tabBar()
        let barDataSource = delegate.tabBarDataSource()
        pageViewController.addBar(
            bar,
            dataSource: barDataSource,
            at: .custom(view: headerViewController.view, layout: { bar in
                bar.translatesAutoresizingMaskIntoConstraints = false
                headerViewController.view.addSubview(bar)
                NSLayoutConstraint.activate([
                    bar.leadingAnchor.constraint(equalTo: headerViewController.view.leadingAnchor),
                    bar.trailingAnchor.constraint(equalTo: headerViewController.view.trailingAnchor),
                    bar.bottomAnchor.constraint(equalTo: headerViewController.view.bottomAnchor),
                    bar.heightAnchor.constraint(equalToConstant: headerViewController.minimalHeight()).priority(.defaultHigh),
                ])
            })
        )
        
        pageViewController.tabBarPageViewDelegate = self
    }
    
}

extension TabBarPagerController {
    private func updatePageObservation() {
        guard let dataSource = self.dataSource else { return }
        let pageViewController = dataSource.pageViewController()
        
        // Note:
        // The `index` was updated when call from `TabBarPageViewDelegate`
        guard let index = pageViewController.currentIndex else { return }
        guard let page = pageViewController.currentViewController as? TabBarPage else { return }
        
        // observe content size change
        observePageContentSize(scrollView: page.pageScrollView, at: index)
        
        // set pan gesture relay
        page.pageScrollView.panGestureRecognizer.require(toFail: relayScrollView.panGestureRecognizer)
    }
    
    private func observePageContentSize(scrollView: UIScrollView, at pageIndex: PageIndex) {
        // update content size
        updateRelayScrollViewContentSize(scrollView: scrollView, at: pageIndex)
        
        // set KVO if needs
        if contentSizeObservations[pageIndex] == nil {
            contentSizeObservations[pageIndex] = scrollView.observe(\.contentSize, options: [.new]) { [weak self] scrollView, _ in
                guard let self = self else { return }
                self.updateRelayScrollViewContentSize(scrollView: scrollView, at: pageIndex)
            }
        }
    }

    private func updateRelayScrollViewContentSize(scrollView: UIScrollView, at pageIndex: PageIndex) {
        guard let dataSource = self.dataSource else {
            assertionFailure()
            return
        }
        
        let pageViewController = dataSource.pageViewController()
        guard pageViewController.currentIndex == pageIndex else {
            return
        }
        
        let headerViewController = dataSource.headerViewController()
        let headerMinimalHeight = headerViewController.minimalHeight()
        
        let pageHeight = max(
            scrollView.contentSize.height,
            containerScrollView.frame.height - headerMinimalHeight - containerScrollView.safeAreaInsets.bottom
        )
        let headerViewHeight: CGFloat = headerViewController.view.frame.height
        let contentSize = CGSize(
            width: containerScrollView.contentSize.width,
            height: pageHeight + headerViewHeight
        )
        
        // Warning:
        // For AutoLayout self-self cell
        // The tableView / collectionView should set estimatedRowHeight for smoothy scroll
        relayScrollView.contentSize = contentSize
    
    }
}

// MARK: - UIScrollViewDelegate
extension TabBarPagerController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch scrollView {
        case relayScrollView:
            guard let dataSource = self.dataSource else { return }
            let pageViewController = dataSource.pageViewController()
            guard let currentPageIndex = pageViewController.currentIndex else {
                assertionFailure()
                return
            }
            
            defer {
                delegate?.tabBarPagerController(self, didScroll: scrollView)
            }

            contentOffsets[currentPageIndex] = scrollView.contentOffset.y
            
            let topMaxContentOffsetY = pageViewController.view.frame.minY - dataSource.headerViewController().minimalHeight() - containerScrollView.safeAreaInsets.top
            if scrollView.contentOffset.y < topMaxContentOffsetY {
                containerScrollView.contentOffset.y = scrollView.contentOffset.y
                delegate?.resetPageContentOffset(self)
                contentOffsets.removeAll()
            } else {
                containerScrollView.contentOffset.y = topMaxContentOffsetY
                if let page = pageViewController.currentViewController as? TabBarPage {
                    let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                    page.pageScrollView.contentOffset.y = contentOffsetY
                }
            }
            
        default:
            assertionFailure()
        }
    }
}

// MARK: - TabBarPageViewDelegate
extension TabBarPagerController: TabBarPageViewDelegate {
    public func pageViewController(_ pageViewController: TabmanViewController, tabBarPage page: TabBarPage, at pageIndex: PageIndex) {
        // observe new page
        updatePageObservation()
        
        // set content offset
        relayScrollView.contentOffset.y = contentOffsets[pageIndex] ?? containerScrollView.contentOffset.y
    }
}

extension NSLayoutConstraint {
    func priority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
