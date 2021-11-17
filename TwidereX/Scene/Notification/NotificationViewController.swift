//
//  NotificationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Tabman
import Pageboy

final class NotificationViewController: TabmanViewController, NeedsDependency {

    let logger = Logger(subsystem: "NotificationViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = NotificationViewModel(context: context, coordinator: coordinator)
    
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
        
        #if DEBUG
        setupDebugAction()
        #endif
    }

}

extension NotificationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel
        viewModel.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewControllers in
                guard let self = self else { return }
                self.reloadData()
                self.bounces = viewControllers.count > 1
                
            }
            .store(in: &disposeBag)
        
        setupSegmentedControl(scopes: viewModel.scopes)
        viewModel.$scopes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scopes in
                guard let self = self else { return }
                self.setupSegmentedControl(scopes: scopes)
                self.navigationItem.titleView = scopes.count > 1 ? self.pageSegmentedControl : nil
            }
            .store(in: &disposeBag)
        
        viewModel.$currentPageIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentPageIndex in
                guard let self = self else { return }
                if self.pageSegmentedControl.selectedSegmentIndex != currentPageIndex {
                    self.pageSegmentedControl.selectedSegmentIndex = currentPageIndex
                }
            }
            .store(in: &disposeBag)
        
        pageSegmentedControl.addTarget(self, action: #selector(NotificationViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
}

#if DEBUG
extension NotificationViewController {
    func setupDebugAction() {
        guard let index = currentIndex,
              index < viewModel.viewControllers.count
        else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        let viewController = viewModel.viewControllers[index]
        
        if let viewController = viewController as? NotificationTimelineViewController {
            navigationItem.rightBarButtonItem = viewController.debugActionBarButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
}
#endif

extension NotificationViewController {
    private func setupSegmentedControl(scopes: [NotificationViewModel.Scope]) {
        pageSegmentedControl.removeAllSegments()
        for (i, scope) in scopes.enumerated() {
            pageSegmentedControl.insertSegment(withTitle: scope.title, at: i, animated: false)
        }
        
        // set initial selection
        guard !pageSegmentedControl.isSelected else { return }
        if viewModel.currentPageIndex < pageSegmentedControl.numberOfSegments {
            pageSegmentedControl.selectedSegmentIndex = viewModel.currentPageIndex
        } else {
            pageSegmentedControl.selectedSegmentIndex = 0
        }
    }
}

extension NotificationViewController {
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let index = sender.selectedSegmentIndex
        scrollToPage(.at(index: index), animated: true, completion: nil)
    }
}
