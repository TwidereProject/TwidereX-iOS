//
//  UserMediaTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class UserMediaTimelineViewController: GridTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserMediaTimelineViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch viewModel.kind {
        case .user(let userTimelineContext):
            title = userTimelineContext.timelineKind.title
        default:
            assertionFailure()
        }
        
        guard let viewModel = self.viewModel as? UserMediaTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            statusMediaGalleryCollectionCellDelegate: self
        )
    }
    
}
