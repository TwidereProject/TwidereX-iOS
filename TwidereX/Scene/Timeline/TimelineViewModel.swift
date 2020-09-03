//
//  TimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

final class TimelineViewModel: NSObject {
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    weak var collectionView: UICollectionView?
    
    // output
    var currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, TimelineIndex>?
    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = {
            let fetchRequest = TimelineIndex.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
    }
    
}

extension TimelineViewModel {
    enum Section {
        case entry
        case topLoadMore
        case middleLoadMore
        case bottomLoadMore
    }
    
    func setupDiffableDataSource(for collectionView: UICollectionView) {
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, timelineIndex -> UICollectionViewCell? in
            return nil
        }
        collectionView.dataSource = diffableDataSource
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TimelineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<TimelineViewModel.Section, TimelineIndex>
        diffableDataSource?.apply(snapshot)
    }
}
