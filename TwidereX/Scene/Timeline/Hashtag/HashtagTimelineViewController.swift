//
//  HashtagTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class HashtagTimelineViewController: ListTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension HashtagTimelineViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch viewModel.kind {
        case .hashtag(let hashtag):
            title = "#" + hashtag

        default:
            assertionFailure()
        }
        
        guard let viewModel = self.viewModel as? HashtagTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
    }
    
}
