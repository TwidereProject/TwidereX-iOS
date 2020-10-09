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
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
    let userID: CurrentValueSubject<String?, Never>
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    let userTimelineTweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
    weak var tableView: UITableView?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    lazy var stateMachinePublisher = CurrentValueSubject<State, Never>(State.Initial(viewModel: self))
    let timelineItems = CurrentValueSubject<[TimelineItem], Never>([])
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
        
        Publishers.CombineLatest(
            timelineItems.eraseToAnyPublisher(),
            stateMachinePublisher.eraseToAnyPublisher()
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, state in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)

            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItem>()
            snapshot.appendSections([.main])
            let items = (self.fetchedResultsController.fetchedObjects ?? []).map { TimelineItem.userTimelineItem(objectID: $0.objectID) }
            snapshot.appendItems(items)
            if !items.isEmpty, self.stateMachine.canEnterState(State.LoadingMore.self) ||
                state is State.LoadingMore {
                snapshot.appendItems([.bottomLoader], toSection: .main)
            }
            self.diffableDataSource?.apply(snapshot)
        }
        .store(in: &disposeBag)
        
        userTimelineTweetIDs
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
        
        context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: currentTwitterAuthentication)
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
    
    private static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, userID: String) {
        HomeTimelineViewModel.configure(cell: cell, tweetInterface: tweet)
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
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, TimelineItem>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let userID = self.userID.value else { return nil }
            
            switch item {
            case .userTimelineItem(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell

                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    UserTimelineViewModel.configure(cell: cell, tweet: tweet, userID: userID)
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

        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        guard snapshot.numberOfItems == userTimelineTweetIDs.value.count else { return }
        let items = snapshot.itemIdentifiers.map { TimelineItem.userTimelineItem(objectID: $0) }
        timelineItems.value = items
    }
    
}

extension UserTimelineViewModel {
    
    enum UserTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidUserID
        case invalidAnchorToLoadMore
    }
    
    func fetchLatest() -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        guard let authentication = currentTwitterAuthentication.value,
              let authorization = try? authentication.authorization(appSecret: .shared) else {
            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
        }
        guard let userID = self.userID.value, !userID.isEmpty else {
            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
        }
        
        return context.apiService.twitterUserTimeline(count: 20, userID: userID, authorization: authorization)
    }
    
    func loadMore() -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        guard let authentication = currentTwitterAuthentication.value,
              let authorization = try? authentication.authorization(appSecret: .shared) else {
            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
        }
        guard let userID = self.userID.value, !userID.isEmpty else {
            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
        }
        guard let oldestTweet = fetchedResultsController.fetchedObjects?.last else {
            return Fail(error: UserTimelineError.invalidAnchorToLoadMore).eraseToAnyPublisher()
        }
        
        let maxID = oldestTweet.idStr
        return context.apiService.twitterUserTimeline(count: 20, userID: userID, maxID: maxID, authorization: authorization)
    }
}

extension UserTimelineViewModel {
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.user-timeline.second-step-timer-triggered")
}
