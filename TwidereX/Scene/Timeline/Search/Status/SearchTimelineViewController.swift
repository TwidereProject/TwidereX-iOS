//
//  SearchTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class SearchTimelineViewController: ListTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension SearchTimelineViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = self.viewModel as? SearchTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
    }

}

// MARK: - DeselectRowTransitionCoordinator
extension SearchTimelineViewController: DeselectRowTransitionCoordinator {
    func deselectRow(with coordinator: UIViewControllerTransitionCoordinator, animated: Bool) {
        tableView.deselectRow(with: coordinator, animated: animated)
    }
}
