//
//  HomeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class HomeTimelineViewController: TimelineViewController {

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Timeline.title
    
        #if DEBUG
        navigationItem.rightBarButtonItem = debugActionBarButtonItem
        #endif
        
        guard let viewModel = self.viewModel as? HomeTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )
    }
    
}
