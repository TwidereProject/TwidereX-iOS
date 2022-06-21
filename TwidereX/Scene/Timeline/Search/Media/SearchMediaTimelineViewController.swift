//
//  SearchMediaTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class SearchMediaTimelineViewController: GridTimelineViewController {
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchMediaTimelineViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewModel = self.viewModel as? SearchMediaTimelineViewModel else {
            assertionFailure()
            return
        }
        
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            statusMediaGalleryCollectionCellDelegate: self
        )
    }
    
}
