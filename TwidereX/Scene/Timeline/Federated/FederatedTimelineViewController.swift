//
//  FederatedTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class FederatedTimelineViewController: ListTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension FederatedTimelineViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch viewModel.kind {
        case .public(let local):
            title = local ? L10n.Scene.Local.title : L10n.Scene.Federated.title

        default:
            assertionFailure()
        }
        
        guard let viewModel = self.viewModel as? FederatedTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
    }
    
}
