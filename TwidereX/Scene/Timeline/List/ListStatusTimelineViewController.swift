//
//  ListStatusTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class ListStatusTimelineViewController: ListTimelineViewController {
    
    let menuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "ellipsis")
        return barButtonItem
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ListStatusTimelineViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = self.viewModel as? ListStatusTimelineViewModel else {
            assertionFailure()
            return
        }
        
        switch viewModel.kind {
        case .list:
            viewModel.$title
                .receive(on: DispatchQueue.main)
                .sink { [weak self] title in
                    guard let self = self else { return }
                    self.title = title
                }
                .store(in: &disposeBag)

        default:
            assertionFailure()
        }
        
        navigationItem.rightBarButtonItem = menuBarButtonItem
        Task {
            guard case let .list(list) = self.viewModel.kind else { return }
            do {
                let menu = try await DataSourceFacade.createMenuForList(
                    dependency: self,
                    list: list,
                    authenticationContext: self.viewModel.authContext.authenticationContext
                )
                self.menuBarButtonItem.menu = menu
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }   // end Task
        
        viewModel.$isDeleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleted in
                guard let self = self else { return }
                guard isDeleted else { return }
                
                // pop if current view controller on screen when isDeleted
                if self.navigationController?.visibleViewController === self {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &disposeBag)
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
    }

}
