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
import AlamofireImage
import DateToolsSwift

final class TimelineViewModel: NSObject {
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    weak var collectionView: UICollectionView?
    
    // output
    var currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, NSManagedObjectID>?
    
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
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, managedObjectID -> UICollectionViewCell? in
            let managedObjectContext = self.fetchedResultsController.managedObjectContext
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: TimelineCollectionViewCell.self), for: indexPath) as! TimelineCollectionViewCell
            managedObjectContext.performAndWait {
                let timelineIndex = self.fetchedResultsController.managedObjectContext.object(with: managedObjectID) as! TimelineIndex
                TimelineViewModel.configure(cell: cell, timelineIndex: timelineIndex)
            }
            return cell
        }
        collectionView.dataSource = diffableDataSource
    }
    
    static func configure(cell: TimelineCollectionViewCell, timelineIndex: TimelineIndex) {
        if let tweet = timelineIndex.tweet {
            configure(cell: cell, tweet: tweet)
        }
    }
    
    private static func configure(cell: TimelineCollectionViewCell, tweet: Tweet) {
        // set avatar
        if let avatarImageURL = tweet.user.avatarImageURL() {
            let placeholderImage = UIImage
                .placeholder(size: TimelineCollectionViewCell.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            let filter = ScaledToSizeCircleFilter(size: TimelineCollectionViewCell.avatarImageViewSize)
            cell.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        }
        
        // set name and username
        cell.nameLabel.text = tweet.user.name
        cell.usernameLabel.text = tweet.user.screenName.flatMap { "@" + $0 }
        
        // set date
        cell.dateLabel.text = tweet.createdAt.shortTimeAgoSinceNow
        cell.dateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                cell.dateLabel.text = tweet.createdAt.shortTimeAgoSinceNow
            }
        
        // set text
        cell.textlabel.text = tweet.text
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TimelineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<TimelineViewModel.Section, NSManagedObjectID>
        DispatchQueue.main.async {
            self.diffableDataSource?.apply(
                snapshot,
                animatingDifferences: false,
                completion: {
                
                }
            )
            //self.diffableDataSource?.apply(snapshot)
        }
    }
}
