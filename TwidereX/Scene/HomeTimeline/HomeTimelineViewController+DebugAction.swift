//
//  HomeTimelineViewController+DebugAction.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import TwitterAPI

#if DEBUG
import ZIPFoundation
import FLEX
#endif

#if DEBUG
@available(iOS 14.0, *)
extension HomeTimelineViewController {
    
    var debugActionBarButtonItem: UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(title: "More", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: moreMenu)
        return barButtonItem
    }
    
    var moreMenu: UIMenu {
        return UIMenu(
            title: "Debug Tools",
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                UIAction(title: "Show FLEX", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showFLEXAction(action)
                }),
                UIAction(title: "Show Stub Timeline", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showStubTimelineAction(action)
                }),
                moveMenu,
                dropMenu,
                UIAction(title: "Enable Bottom Fetcher", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.enableBottomFetcher(action)
                }),
                UIAction(title: "Show Account unlock alert", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    let error = Twitter.API.Error.ResponseError(
                        httpResponseStatus: .forbidden,
                        twitterAPIError: .accountIsTemporarilyLocked(message: "")
                    )
                    self.context.apiService.error.send(.explicit(.twitterResponseError(error)))
                }),
                UIAction(title: "Show Rate Limit alert", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    let error = Twitter.API.Error.ResponseError(
                        httpResponseStatus: .tooManyRequests,
                        twitterAPIError: .rateLimitExceeded
                    )
                    self.context.apiService.error.send(.explicit(.twitterResponseError(error)))
                }),
                UIAction(title: "Export Database", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.exportDatabase(action)
                }),
                UIAction(title: "Import Database", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.importDatabase(action)
                }),
                UIAction(title: "Corner Smooth Preview", attributes: [], state: .off, handler: { [weak self] action in
                    guard let self = self else { return }
                    self.cornerSmoothPreview(action)
                })
            ]
        )
    }
    
    var moveMenu: UIMenu {
        return UIMenu(
            title: "Move to…",
            image: UIImage(systemName: "arrow.forward.circle"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "First Gap", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToTopGapAction(action)
                }),
                UIAction(title: "First Protected Tweet", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstProtectedTweet(action)
                }),
                UIAction(title: "First Protected User", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstProtectedUser(action)
                }),
                UIAction(title: "First Reply Tweet", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstReplyTweet(action)
                }),
                UIAction(title: "First Reply Retweet", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstReplyRetweet(action)
                }),
                UIAction(title: "First Video Tweet", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstVideoTweet(action)
                }),
                UIAction(title: "First GIF Tweet", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstGIFTweet(action)
                }),
            ]
        )
    }
    
    var dropMenu: UIMenu {
        return UIMenu(
            title: "Drop…",
            image: UIImage(systemName: "minus.circle"),
            identifier: nil,
            options: [],
            children: [50, 100, 150, 200, 250, 300].map { count in
                UIAction(title: "Drop Recent \(count) Tweets", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.dropRecentTweetsAction(action, count: count)
                })
            }
        )
    }
    
}

extension HomeTimelineViewController {
    
    @objc private func showFLEXAction(_ sender: UIAction) {
        FLEXManager.shared.showExplorer()
    }
    
    @objc private func showStubTimelineAction(_ sender: UIAction) {
        coordinator.present(scene: .stubTimeline, from: self, transition: .show)
    }
    
    @objc private func moveToTopGapAction(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .middleLoader: return true
            default:                        return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
    
    @objc private func moveToFirstProtectedTweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
                return targetTweet.author.protected
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found protected tweet")
        }
    }
    
    @objc private func moveToFirstProtectedUser(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet) else { return false }
                return targetTweet.author.protected
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found protected tweet")
        }
    }
    
    @objc private func moveToFirstReplyTweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet) else { return false }
                return targetTweet.inReplyToTweetID != nil
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found reply tweet")
        }
    }
    
    @objc private func moveToFirstReplyRetweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet?.retweet) else { return false }
                return targetTweet.inReplyToTweetID != nil
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found reply retweet")
        }
    }
    
    @objc private func moveToFirstVideoTweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
                guard let type = targetTweet.media?.first?.type else { return false }
                return type == "video"
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found video tweet")
        }
    }
    
    @objc private func moveToFirstGIFTweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
                guard let type = targetTweet.media?.first?.type else { return false }
                return type == "animated_gif"
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found video tweet")
        }
    }
    
    @objc private func dropRecentTweetsAction(_ sender: UIAction, count: Int) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        
        let droppingObjectIDs = snapshotTransitioning.itemIdentifiers.prefix(count).compactMap { item -> NSManagedObjectID? in
            switch item {
            case .homeTimelineIndex(let objectID, _):   return objectID
            default:                                    return nil
            }
        }
        context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
            guard let self = self else { return }
            for objectID in droppingObjectIDs {
                guard let object = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? TimelineIndex else { continue }
                self.context.apiService.backgroundManagedObjectContext.delete(object.tweet!)
                self.context.apiService.backgroundManagedObjectContext.delete(object)
            }
        }
        .sink { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
    
    @objc private func enableBottomFetcher(_ sender: UIAction) {
        if let last = viewModel.fetchedResultsController.fetchedObjects?.last {
            let objectID = last.objectID
            context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
                guard let self = self else { return }
                let object = self.context.apiService.backgroundManagedObjectContext.object(with: objectID) as! TimelineIndex
                object.update(hasMore: true)
            }
            .sink { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        }
        
    }
    
    @objc private func exportDatabase(_ sender: UIAction) {
        let storeURL = URL.storeURL(for: "group.com.twidere.twiderex", databaseName: "shared")
        let databaseFolderURL = storeURL.deletingLastPathComponent()
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let archiveSourceDirectoryURL = temporaryDirectoryURL.appendingPathComponent("Archive")
        let archiveURL = temporaryDirectoryURL.appendingPathComponent("database.zip")
        
        DispatchQueue(label: "com.twidere.twiderex", qos: .userInitiated).async {
            do {
                try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.copyItem(at: databaseFolderURL, to: archiveSourceDirectoryURL)
                // zip under DEBUG mode is pretty slow (may CRC performance issue of ZIPFoundation)
                try FileManager.default.zipItem(at: archiveSourceDirectoryURL, to: archiveURL, shouldKeepParent: false, compressionMethod: .none)
                print(temporaryDirectoryURL)
            } catch {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: archive database fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            }
            
            let activityViewController = UIActivityViewController(activityItems: [archiveURL], applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func importDatabase(_ sender: UIAction) {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.text"], in: .open)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
//        let storeURL = URL.storeURL(for: "group.com.twidere.twiderex", databaseName: "shared")
//        let databaseFolderURL = storeURL.deletingLastPathComponent()
//
//        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
//        let archiveSourceDirectoryURL = temporaryDirectoryURL.appendingPathComponent("Archive")
//        let archiveURL = temporaryDirectoryURL.appendingPathComponent("database.zip")
//
//        DispatchQueue(label: "com.twidere.twiderex", qos: .userInitiated).async {
//            do {
//                try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
//                try FileManager.default.copyItem(at: databaseFolderURL, to: archiveSourceDirectoryURL)
//                // zip under DEBUG mode is pretty slow (may CRC performance issue of ZIPFoundation)
//                try FileManager.default.zipItem(at: archiveSourceDirectoryURL, to: archiveURL, shouldKeepParent: false, compressionMethod: .none)
//                print(temporaryDirectoryURL)
//            } catch {
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: archive database fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            }
//
//            let activityViewController = UIActivityViewController(activityItems: [archiveURL], applicationActivities: nil)
//            DispatchQueue.main.async {
//                self.present(activityViewController, animated: true, completion: nil)
//            }
//        }
    }
    
    @objc private func cornerSmoothPreview(_ sender: UIAction) {
        let cornerSmoothPreviewViewController = CornerSmoothPreviewViewController()
        present(cornerSmoothPreviewViewController, animated: true, completion: nil)
    }

    
}

extension HomeTimelineViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
}

#endif
