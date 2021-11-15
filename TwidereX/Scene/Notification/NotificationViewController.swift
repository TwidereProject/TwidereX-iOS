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
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.reloadData()
            }
            .store(in: &disposeBag)
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
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
}
