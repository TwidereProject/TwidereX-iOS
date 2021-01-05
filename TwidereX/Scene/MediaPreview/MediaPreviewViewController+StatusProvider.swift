//
//  MediaPreviewViewController+StatusProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

// MARK: - StatusProvider
extension MediaPreviewViewController: StatusProvider {
    
    func tweet() -> Future<Tweet?, Never> {
        return Future { promise in
            guard case let .tweet(meta) = self.viewModel.rootItem else {
                promise(.success(nil))
                return
            }

            let managedObjectContext = self.context.managedObjectContext
            managedObjectContext.perform {
                let tweet = managedObjectContext.object(with: meta.tweetObjectID) as? Tweet
                promise(.success(tweet))
            }
        }
    }
    
    func tweet(for cell: UICollectionViewCell) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
}
