//
//  UserTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import AlamofireImage

class UserTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<Tweet>
    let userID: CurrentValueSubject<String?, Never>
    weak var tableView: UITableView?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.PermissionDenied(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    let tweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
    let items = CurrentValueSubject<[Item], Never>([])
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext, userID: String?) {
        self.context = context
        self.fetchedResultsController = {
            let fetchRequest = Tweet.sortedFetchRequest
            fetchRequest.predicate = Tweet.predicate(idStrs: [])
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
        self.userID = CurrentValueSubject(userID)
        super.init()
        
        self.fetchedResultsController.delegate = self
        
        items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                os_log("%{public}s[%{public}ld], %{public}s: items did change", ((#file as NSString).lastPathComponent), #line, #function)

                var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Reloading, is State.Idle, is State.LoadingMore, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is State.PermissionDenied:
                        snapshot.appendItems([.permissionDenied], toSection: .main)
                    default:
                        break
                    }
                }
                
                diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
            }
            .store(in: &disposeBag)
        
        tweetIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = Tweet.predicate(idStrs: ids)
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let userInfo: [AnyHashable : Any] = ["userID": self.userID.value ?? ""]
                NotificationCenter.default.post(name: UserTimelineViewModel.secondStepTimerTriggered, object: nil, userInfo: userInfo)
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewModel {
    enum LoadingStatus {
        case noMore
        case idle
        case loading
    }
}

extension UserTimelineViewModel {
    
    private static func configure(cell: TimelinePostTableViewCell, readableLayoutFrame: CGRect? = nil, videoPlaybackService: VideoPlaybackService, tweet: Tweet, userID: String, requestUserID: String) {
        HomeTimelineViewModel.configure(cell: cell, readableLayoutFrame: readableLayoutFrame, videoPlaybackService: videoPlaybackService, tweet: tweet, requestUserID: requestUserID)
        internalConfigure(cell: cell, tweet: tweet, userID: userID)
    }

    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: Tweet, userID: String) {
        // tweet date updater
        let createdAt = (tweet.retweet ?? tweet).createdAt
        NotificationCenter.default.publisher(for: UserTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { notification in
                guard let incomingUserID = notification.userInfo?["userID"] as? String,
                      incomingUserID == userID else { return }
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)

        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: UserTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { notification in
                    guard let incomingUserID = notification.userInfo?["userID"] as? String,
                          incomingUserID == userID else { return }
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
    }
    
}

extension UserTimelineViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, Item>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let userID = self.userID.value else {
                assertionFailure()
                return nil
            }
            
            switch item {
            case .tweet(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let activeTwitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestTwitterUserID = activeTwitterAuthenticationBox?.twitterUserID ?? ""
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    UserTimelineViewModel.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, videoPlaybackService: self.context.videoPlaybackService, tweet: tweet, userID: userID, requestUserID: requestTwitterUserID)
                    HomeTimelineViewModel.configure(cell: cell, overrideTraitCollection: self.context.overrideTraitCollection.value)
                }
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            default:
                assertionFailure()
                return nil
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension UserTimelineViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = tweetIDs.value
        let tweets = fetchedResultsController.fetchedObjects ?? []
        guard tweets.count == indexes.count else { return }
        
        let items: [Item] = tweets
            .compactMap { tweet in
                indexes.firstIndex(of: tweet.id).map { index in (index, tweet) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.tweet(objectID: $0.1.objectID) }
        self.items.value = items
    }
    
}

extension UserTimelineViewModel {
    
    enum UserTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidUserID
        case invalidAnchorToLoadMore
    }
    
    func fetchLatest() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
        }
        guard let userID = self.userID.value, !userID.isEmpty else {
            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
        }
        
        return context.apiService.twitterUserTimeline(count: 20, userID: userID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
    }
    
    func loadMore() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
        }
        guard let userID = self.userID.value, !userID.isEmpty else {
            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
        }
        guard let oldestTweetID = tweetIDs.value.last else {
            return Fail(error: UserTimelineError.invalidAnchorToLoadMore).eraseToAnyPublisher()
        }
        
        let maxID = oldestTweetID
        return context.apiService.twitterUserTimeline(count: 20, userID: userID, maxID: maxID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
    }
    
}

extension UserTimelineViewModel {
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.user-timeline.second-step-timer-triggered")
}
