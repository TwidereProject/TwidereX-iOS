//
//  UserTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

class UserTimelineViewController: ListTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch viewModel.kind {
        case .user(let userTimelineContext):
            title = userTimelineContext.timelineKind.title
        default:
            assertionFailure()
        }
        
        guard let viewModel = self.viewModel as? UserTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
    }
    
}
