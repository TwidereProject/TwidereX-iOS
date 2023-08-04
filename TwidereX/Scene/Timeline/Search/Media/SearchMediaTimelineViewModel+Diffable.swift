//
//  SearchMediaTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import TwidereCore

extension SearchMediaTimelineViewModel {
    @MainActor func setupDiffableDataSource(
        collectionView: UICollectionView,
        statusMediaGalleryCollectionCellDelegate: StatusMediaGalleryCollectionCellDelegate
    ) {
        let configuration = StatusMediaGallerySection.Configuration(
            statusMediaGalleryCollectionCellDelegate: statusMediaGalleryCollectionCellDelegate
        )
        diffableDataSource = StatusMediaGallerySection.diffableDataSource(
            collectionView: collectionView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        statusRecordFetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let _ = self.diffableDataSource else { return }
                
                let recordsCount = records.count
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(recordsCount) objects")
                Task { @MainActor in
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(recordsCount) feeds")
                    }
                    
                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                        snapshot.appendSections([.main, .footer])
                        let newItems: [StatusItem] = records.map { .status($0) }
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()
                    
                    switch self.stateMachine.currentState {
                    case is LoadOldestState.NoMore:
                        break
                    default:
                        newSnapshot.appendItems([.bottomLoader], toSection: .footer)
                    }
                    
                    self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }   // end Task
            }
            .store(in: &disposeBag)
    }   // end func setupDiffableDataSource
}
