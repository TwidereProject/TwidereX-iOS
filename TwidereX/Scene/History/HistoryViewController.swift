//
//  HistoryViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Tabman
import Pageboy
import TwidereCore

final class HistoryViewController: TabmanViewController, NeedsDependency, DrawerSidebarTransitionHostViewController {
    
    let logger = Logger(subsystem: "HistoryViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: HistoryViewModel!
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    private(set) lazy var pageSegmentedControl = UISegmentedControl()
    
    override func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: TabmanViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        super.pageboyViewController(
            pageboyViewController,
            didScrollToPageAt: index,
            direction: direction,
            animated: animated
        )
        
        viewModel.currentPageIndex = index
    }
    
}

extension HistoryViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isScrollEnabled = false     // inner pan gesture untouchable. workaround to prevent swipe conflict
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)
        
        view.backgroundColor = .systemBackground

        // TODO:
        // setupSegmentedControl(scopes: viewModel.scopes)
        // navigationItem.titleView = pageSegmentedControl
        
        title = "Hisotry"

        dataSource = viewModel
    }
    
}

extension HistoryViewController {
    private func setupSegmentedControl(scopes: [HistoryViewModel.Scope]) {
        pageSegmentedControl.removeAllSegments()
        for (i, scope) in scopes.enumerated() {
            let title = scope.title(platform: viewModel.platform)
            pageSegmentedControl.insertSegment(withTitle: title, at: i, animated: false)
        }
        
        // set initial selection
        guard !pageSegmentedControl.isSelected else { return }
        if viewModel.currentPageIndex < pageSegmentedControl.numberOfSegments {
            pageSegmentedControl.selectedSegmentIndex = viewModel.currentPageIndex
        } else {
            pageSegmentedControl.selectedSegmentIndex = 0
        }
        
        pageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageSegmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 240)
        ])
    }
}
