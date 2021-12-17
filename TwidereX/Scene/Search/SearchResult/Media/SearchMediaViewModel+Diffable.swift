//
//  SearchMediaViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension SearchMediaViewModel {
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
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusMediaGallerySection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        statusRecordFetchedResultController.records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let _ = self.diffableDataSource else { return }

                let recordsCount = records.count
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(recordsCount) objects")
                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(recordsCount) feeds")
                    }

                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusMediaGallerySection, StatusItem> = {
                        var snapshot = NSDiffableDataSourceSnapshot<StatusMediaGallerySection, StatusItem>()
                        snapshot.appendSections([.main, .footer])
                        let newItems: [StatusItem] = records.map { .status($0) }
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()

                    if let currentState = self.stateMachine.currentState {
                        switch currentState {
                        case is State.Idle, is State.Loading, is State.Fail:
                            newSnapshot.appendItems([.bottomLoader], toSection: .footer)
                        case is State.NoMore:
                            break
                        default:
                            break
                        }
                    }

                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }
            }
            .store(in: &disposeBag)
    }   // end func setupDiffableDataSource
    
    @MainActor private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusMediaGallerySection, StatusItem>,
        animatingDifferences: Bool
    ) async {
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
