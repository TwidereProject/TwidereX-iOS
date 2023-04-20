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
import CoreData
import CoreDataStack
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
    
    let optionBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"))
    
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

        setupSegmentedControl(scopes: viewModel.scopes)
        navigationItem.titleView = pageSegmentedControl
        pageSegmentedControl.addTarget(self, action: #selector(HistoryViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)
        
        navigationItem.rightBarButtonItem = optionBarButtonItem
        optionBarButtonItem.menu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
            UIAction(title: "Clear", image: UIImage(systemName: "minus.circle"), identifier: nil, discoverabilityTitle: nil, attributes: [.destructive], state: .off, handler: { [weak self] action in
                guard let self = self else { return }
                Task {
                    let managedObjectContext = self.context.backgroundManagedObjectContext
                    let acct = self.viewModel.authContext.authenticationContext.acct
                    try await managedObjectContext.performChanges {
                        let request = History.sortedFetchRequest
                        request.predicate = History.predicate(acct: acct)
                        let histories = try managedObjectContext.fetch(request)
                        for history in histories {
                            managedObjectContext.delete(history)
                        }
                    }
                }   // end Task
            })
        ])
        
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

extension HistoryViewController {
    
    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let index = sender.selectedSegmentIndex
        scrollToPage(.at(index: index), animated: true, completion: nil)
    }

}

// MARK: - AuthContextProvider
extension HistoryViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}
