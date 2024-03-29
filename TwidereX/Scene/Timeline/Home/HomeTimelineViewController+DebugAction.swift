//
//  HomeTimelineViewController+DebugAction.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

#if DEBUG

import os.log
import UIKit
import CoreData
import CoreDataStack
import TwitterSDK
import MetaTextKit
import MetaTextArea
import SwiftMessages

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
                showMenu,
                moveMenu,
                dropMenu,
                debugMenu,
//                UIAction(title: "Show Account unlock alert", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    let error = Twitter.API.Error.ResponseError(
//                        httpResponseStatus: .forbidden,
//                        twitterAPIError: .accountIsTemporarilyLocked(message: "")
//                    )
//                    self.context.apiService.error.send(.explicit(.twitterResponseError(error)))
//                }),
//                UIAction(title: "Show Rate Limit alert", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    let error = Twitter.API.Error.ResponseError(
//                        httpResponseStatus: .tooManyRequests,
//                        twitterAPIError: .rateLimitExceeded
//                    )
//                    self.context.apiService.error.send(.explicit(.twitterResponseError(error)))
//                }),
//                UIAction(title: "Export Database", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    self.exportDatabase(action)
//                }),
//                UIAction(title: "Import Database", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    self.importDatabase(action)
//                }),
            ]
        )
    }
    
    var showMenu: UIMenu {
        return UIMenu(
            title: "Show…",
            image: UIImage(systemName: "macwindow.badge.plus"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "Status by ID", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    let alertController = UIAlertController(title: "Enter Status ID", message: nil, preferredStyle: .alert)
                    alertController.addTextField()
                    let showAction = UIAlertAction(title: "Move", style: .default) { [weak self, weak alertController] _ in
                        guard let self = self else { return }
                        guard let textField = alertController?.textFields?.first else { return }
                        guard let id = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else { return }
                        self.showStatusByID(id)
                    }
                    alertController.addAction(showAction)
                    let cancelAction = UIAlertAction.cancel
                    alertController.addAction(cancelAction)
                    self.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: self,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }),
                UIAction(title: "Push Notification", attributes: [], state: .off, handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showPushNotification()
                }),
                UIAction(title: "Account List", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showAccountListAction(action)
                }),
                UIAction(title: "Local Timeline", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showLocalTimelineAction(action)
                }),
                UIAction(title: "Public Timeline", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.showPublicTimelineAction(action)
                }),
                notificationBannerMenu,
                UIAction(title: "Corner Smooth Preview", attributes: [], state: .off, handler: { [weak self] action in
                    guard let self = self else { return }
                    self.cornerSmoothPreview(action)
                }),
            ]
        )
    }
    
    var notificationBannerMenu: UIMenu {
        UIMenu(
            title: "Notification Banner",
            image: UIImage(systemName: "bell.square"),
            identifier: nil,
            options: [],
            children: NotificationBannerView.Style.allCases.map { style in
                UIAction(
                    title: style.rawValue,
                    image: style.iconImage,
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off)
                { [weak self] action in
                    guard let self = self else { return }
                    self.showNotificationBanner(action, style: style)
                }
            }
        )
    }
    
    var moveMenu: UIMenu {
        return UIMenu(
            title: "Move to…",
            image: UIImage(systemName: "arrow.forward.circle"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "Status ID", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    let alertController = UIAlertController(title: "Enter Status ID", message: nil, preferredStyle: .alert)
                    alertController.addTextField()
                    let showAction = UIAlertAction(title: "Move", style: .default) { [weak self, weak alertController] _ in
                        guard let self = self else { return }
                        guard let textField = alertController?.textFields?.first else { return }
                        guard let id = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else { return }
                        self.moveToFirst(action, category: .status(id: id))
                    }
                    alertController.addAction(showAction)
                    let cancelAction = UIAlertAction.cancel
                    alertController.addAction(cancelAction)
                    self.coordinator.present(scene: .alertController(alertController: alertController), from: self, transition: .alertController(animated: true, completion: nil))
                }),
                UIAction(title: "First Gap", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .gap)
                }),
                UIAction(title: "First Quote", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .quote)
                }),
//                UIAction(title: "First Protected Tweet", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    self.moveToFirstProtectedTweet(action)
//                }),
//                UIAction(title: "First Protected User", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    self.moveToFirstProtectedUser(action)
//                }),
//                UIAction(title: "First Reply Tweet", image: nil, attributes: [], handler: { [weak self] action in
//                    guard let self = self else { return }
//                    self.moveToFirstReplyTweet(action)
//                }),
                UIAction(title: "First Video Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .video)
                }),
                UIAction(title: "First GIF Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .gif)
                }),
                UIAction(title: "First Poll Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .poll)
                }),
                UIAction(title: "First Location Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .location)
                }),
                UIAction(title: "First Follows You Author", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .followsYouAuthor)
                }),
                UIAction(title: "First Blocking Author", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .blockingAuthor)
                }),
                UIAction(title: "First Duplicated Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirst(action, category: .duplicated)
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
            children: [
                [1, 2, 5, 10, 20, 50, 100, 150, 200, 250, 300].map { count in
                    UIAction(title: "Drop Recent \(count)", image: nil, attributes: [], handler: { [weak self] action in
                        guard let self = self else { return }
                        self.dropRecentFeedAction(action, count: count)
                    })
                },
                [
                    UIAction(title: "Exclude last", image: nil, attributes: [], handler: { [weak self] action in
                        guard let self = self else { return }
                        self.dropFeedExcludeLastAction(action)
                    }),
                ],
            ].flatMap { $0 }
        )
    }
    
    var debugMenu: UIMenu {
        return UIMenu(
            title: "Debug…",
            image: UIImage(systemName: "square.dashed.inset.fill"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "Display TextView Frame", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.displayTextViewFrame(action)
                }),
                UIAction(title: "Reload TableView", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.reloadTableView(action)
                }),
                UIAction(title: "Reload App", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.coordinator.setup()
                }),
            ]
        )
    }
    
}

extension HomeTimelineViewController {

    @objc private func showStatusByID(_ id: String) {
        Task { @MainActor in
            let authenticationContext = self.viewModel.authContext.authenticationContext
            switch authenticationContext {
            case .twitter:
                let statusThreadViewModel = StatusThreadViewModel(
                    context: self.context,
                    authContext: self.authContext,
                    kind: .twitter(id)
                )
                self.coordinator.present(
                    scene: .statusThread(viewModel: statusThreadViewModel),
                    from: self,
                    transition: .show
                )
            case .mastodon(let authenticationContext):
                let statusThreadViewModel = StatusThreadViewModel(
                    context: self.context,
                    authContext: self.authContext,
                    kind: .mastodon(domain: authenticationContext.domain, id)
                )
                self.coordinator.present(
                    scene: .statusThread(viewModel: statusThreadViewModel),
                    from: self,
                    transition: .show
                )
            }
        }   // end Task
    }
    
    @objc private func showPushNotification() {
         coordinator.present(
            scene: .pushNotificationScratch,
            from: nil,
            transition: .modal(animated: true)
         )
    }
    
    @objc private func showLocalTimelineAction(_ sender: UIAction) {
        let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, authContext: authContext, isLocal: true)
        coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: self, transition: .show)
    }
    
    @objc private func showPublicTimelineAction(_ sender: UIAction) {
        let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, authContext: authContext, isLocal: false)
        coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: self, transition: .show)
    }
    
    @objc private func showAccountListAction(_ sender: UIAction) {
        let accountListViewModel = AccountListViewModel(context: context, authContext: authContext)
        coordinator.present(scene: .accountList(viewModel: accountListViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    enum StatusCategory: Hashable {
        case gap
        case quote
        case gif
        case video
        case poll
        case location
        case followsYouAuthor
        case blockingAuthor
        case status(id: String)
        case duplicated
        
        func match(item: StatusItem, authContext: AuthContext) -> Bool {
            let authenticationContext = authContext.authenticationContext
            switch item {
            case .feed(let record):
                guard let feed = record.object(in: AppContext.shared.managedObjectContext) else { return false }
                if let status = feed.twitterStatus {
                    switch self {
                    case .quote:
                        return status.quote != nil
                    case .gif:
                        return status.attachmentsTransient.contains(where: { attachment in attachment.kind == .animatedGIF })
                    case .video:
                        return status.attachmentsTransient.contains(where: { attachment in attachment.kind == .video })
                    case .poll:
                        return status.poll != nil
                    case .location:
                        return status.locationTransient != nil
                    case .followsYouAuthor:
                        guard case let .twitter(authenticationContext) = authenticationContext else { return false }
                        guard let me = authenticationContext.authenticationRecord.object(in: AppContext.shared.managedObjectContext)?.user else { return false }
                        return (status.repost ?? status).author.following.contains(me)
                    case .blockingAuthor:
                        guard case let .twitter(authenticationContext) = authenticationContext else { return false }
                        guard let me = authenticationContext.authenticationRecord.object(in: AppContext.shared.managedObjectContext)?.user else { return false }
                        return (status.repost ?? status).author.blockingBy.contains(me)
                    case .status(let id):
                        return status.id == id
                    case .duplicated:
                        return false
                    default:
                        return false
                    }
                } else {
                    return false
                }
            case .feedLoader where self == .gap:
                return true
            default:
                return false
            }
        }
        
        func firstMatch(in items: [StatusItem], authContext: AuthContext) -> StatusItem? {
            switch self {
            case .duplicated:
                var index = 0
                while index < items.count - 2 {
                    defer { index += 1 }
                    
                    let this = items[index]
                    let next = items[index + 1]
                    
                    switch (this, next) {
                    case (.feed(let thisRecord), .feed(let nextRecord)):
                        guard let thisFeed = thisRecord.object(in: AppContext.shared.managedObjectContext) else { continue }
                        guard let nextFeed = nextRecord.object(in: AppContext.shared.managedObjectContext) else { continue }
                        
                        if let thisTwitterStatus = thisFeed.twitterStatus,
                           let nextTwitterStatus = nextFeed.twitterStatus
                        {
                            if thisTwitterStatus.id == nextTwitterStatus.id {
                                return this
                            } else {
                                continue
                            }
                        } else if let thisMastodonStatus = thisFeed.mastodonStatus,
                                  let nextMastodonStatus = nextFeed.mastodonStatus
                        {
                            if thisMastodonStatus.id == nextMastodonStatus.id {
                                return this
                            } else {
                                continue
                            }
                        } else {
                            continue
                        }
                    default:
                        continue
                    }
                }
                let logger = Logger(subsystem: "HomeTimelineViewController", category: "DebugAction")
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): not found duplicated in \(index) count items")
                return nil
            default:
                return items.first { item in self.match(item: item, authContext: authContext) }
            }
        }
    }
    
    private func moveToFirst(_ sender: UIAction, category: StatusCategory) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let items = snapshot.itemIdentifiers
        guard let targetItem = category.firstMatch(in: items, authContext: authContext),
              let index = snapshot.indexOfItem(targetItem)
        else { return }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        tableView.blinkRow(at: indexPath)
    }
    
    @objc private func moveToFirstProtectedTweet(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
//                return targetTweet.author.protected
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found protected tweet")
//        }
    }
    
    @objc private func moveToFirstProtectedUser(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet) else { return false }
//                return targetTweet.author.protected
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found protected tweet")
//        }
    }
    
    @objc private func moveToFirstReplyTweet(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet) else { return false }
//                return targetTweet.inReplyToTweetID != nil
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found reply tweet")
//        }
    }
    
    @objc private func moveToFirstReplyRetweet(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet?.retweet) else { return false }
//                return targetTweet.inReplyToTweetID != nil
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found reply retweet")
//        }
    }
    
    @objc private func moveToFirstVideoTweet(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
//                guard let type = targetTweet.media?.first?.type else { return false }
//                return type == "video"
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found video tweet")
//        }
    }
    
    @objc private func moveToFirstGIFTweet(_ sender: UIAction) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        let snapshotTransitioning = diffableDataSource.snapshot()
//        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
//            switch item {
//            case .homeTimelineIndex(let objectID, _):
//                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
//                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
//                guard let type = targetTweet.media?.first?.type else { return false }
//                return type == "animated_gif"
//            default:
//                return false
//            }
//        })
//        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
//            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
//            tableView.blinkRow(at: IndexPath(row: index, section: 0))
//        } else {
//            print("Not found video tweet")
//        }
    }
    
    @objc private func dropRecentFeedAction(_ sender: UIAction, count: Int) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        
        let droppingObjectIDs = snapshot.itemIdentifiers.prefix(count).compactMap { item -> [NSManagedObjectID]? in
            switch item {
            case .feed(let record):
                let managedObjectContext = context.managedObjectContext
                let ids: [NSManagedObjectID] = managedObjectContext.performAndWait {
                    var ids: [NSManagedObjectID] = [record.objectID]
                    if let feed = record.object(in: managedObjectContext) {
                        if let objectID = feed.twitterStatus?.objectID {
                            ids.append(objectID)
                        }
                        if let objectID = feed.mastodonStatus?.objectID {
                            ids.append(objectID)
                        }
                    }
                    return ids
                }
                return ids
            default:
                return nil
            }
        }
        .flatMap { $0 }
        context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
            guard let self = self else { return }
            for objectID in droppingObjectIDs {
                let object = self.context.apiService.backgroundManagedObjectContext.object(with: objectID)
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
    
    @objc private func dropFeedExcludeLastAction(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        dropRecentFeedAction(sender, count: snapshot.itemIdentifiers.count - 1)
    }

    
    @objc private func exportDatabase(_ sender: UIAction) {
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
    
    @objc private func importDatabase(_ sender: UIAction) {
//        let picker = UIDocumentPickerViewController(documentTypes: ["public.text"], in: .open)
//        picker.delegate = self
//        present(picker, animated: true, completion: nil)
        
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
    
    private func showNotificationBanner(_ sender: UIAction, style: NotificationBannerView.Style) {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true

        let bannerView = NotificationBannerView()
        bannerView.configure(style: style)
        bannerView.titleLabel.text = "Title"
        bannerView.messageLabel.text = "Message"

        SwiftMessages.show(config: config, view: bannerView)
    }

    
    @objc private func cornerSmoothPreview(_ sender: UIAction) {
        let cornerSmoothPreviewViewController = CornerSmoothPreviewViewController()
        present(cornerSmoothPreviewViewController, animated: true, completion: nil)
    }

    
}

extension HomeTimelineViewController {
    @objc private func displayTextViewFrame(_ sender: UIAction) {
        MetaTextAreaView.showLayerFrames.toggle()
        tableView.reloadData()
    }
    
    @objc private func reloadTableView(_ sender: UIAction) {
        tableView.reloadData()
    }
}

//extension HomeTimelineViewController: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let url = urls.first else { return }
//
//        do {
//            guard url.startAccessingSecurityScopedResource() else { return }
//            defer { url.stopAccessingSecurityScopedResource() }
//
//        } catch {
//            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//        }
//    }
//}

#endif
