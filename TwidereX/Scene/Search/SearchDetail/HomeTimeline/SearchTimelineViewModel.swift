//
//  SearchTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import AlamofireImage

class SearchTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<Tweet>
    let searchTimelineTweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
    let searchText = CurrentValueSubject<String, Never>("")
    let searchActionPublisher = PassthroughSubject<Void, Never>()

    weak var tableView: UITableView?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    let identifier = UUID()
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    lazy var stateMachinePublisher = CurrentValueSubject<State, Never>(State.Initial(viewModel: self))
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?
    let timelineItems = CurrentValueSubject<[Item], Never>([])
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext) {
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
        super.init()
        
        self.fetchedResultsController.delegate = self

        Publishers.CombineLatest(
            timelineItems.eraseToAnyPublisher(),
            stateMachinePublisher.eraseToAnyPublisher()
        )
        .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] timelineItems, state in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)

            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(timelineItems)
            switch self.stateMachine.currentState {
            case is State.Fail:
                // TODO:
                break
            case is State.Initial, is State.NoMore:
                break
            case is State.Idle, is State.Loading:
                snapshot.appendItems([.bottomLoader], toSection: .main)
            default:
                assertionFailure()
            }
            
            self.diffableDataSource?.apply(snapshot, animatingDifferences: true)
        }
        .store(in: &disposeBag)

        searchTimelineTweetIDs
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
        
        searchActionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.stateMachine.enter(State.Loading.self)
            }
            .store(in: &disposeBag)

        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let userInfo: [AnyHashable : Any] = ["identifier": self.identifier]
                NotificationCenter.default.post(name: SearchTimelineViewModel.secondStepTimerTriggered, object: nil, userInfo: userInfo)
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchTimelineViewModel {
    enum LoadingStatus {
        case noMore
        case idle
        case loading
    }
}

extension SearchTimelineViewModel {
    
    private static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, identifier: UUID, requestUserID: String) {
        HomeTimelineViewModel.configure(cell: cell, tweet: tweet, requestUserID: requestUserID)
        internalConfigure(cell: cell, tweet: tweet, identifier: identifier)
    }

    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: Tweet, identifier: UUID) {
        // tweet date updater
        let createdAt = (tweet.retweet ?? tweet).createdAt
        NotificationCenter.default.publisher(for: SearchTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { notification in
                guard let incomingIdentifier = notification.userInfo?["identifier"] as? UUID,
                      incomingIdentifier == identifier else { return }
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)

        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: SearchTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { notification in
                    guard let incomingIdentifier = notification.userInfo?["identifier"] as? UUID,
                          incomingIdentifier == identifier else { return }
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
    }
    
}

extension SearchTimelineViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, Item>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }

            switch item {
            case .tweet(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let twitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestUserID = twitterAuthenticationBox?.twitterUserID ?? ""
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    SearchTimelineViewModel.configure(cell: cell, tweet: tweet, identifier: self.identifier, requestUserID: requestUserID)
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
extension SearchTimelineViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        guard snapshot.numberOfItems == searchTimelineTweetIDs.value.count else { return }
        let items = snapshot.itemIdentifiers.map { Item.tweet(objectID: $0) }
        timelineItems.value = items
    }
}

extension SearchTimelineViewModel {
    
    enum SearchTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidSearchText
        case invalidAnchorToLoadMore
    }
    
}

extension SearchTimelineViewModel {
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.search-timeline.second-step-timer-triggered")
}
