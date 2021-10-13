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
import TwitterSDK
import AlamofireImage

class UserTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "UserTimelineViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let userIdentifier: CurrentValueSubject<UserIdentifier?, Never>
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.NotAuthorized(viewModel: self),
            State.Blocked(viewModel: self),
            State.Suspended(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
//    let tweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
//    let items = CurrentValueSubject<[Item], Never>([])
    
    init(context: AppContext) {
        self.context = context
        self.userIdentifier = CurrentValueSubject(nil)
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        userIdentifier
            .assign(to: \.value, on: statusRecordFetchedResultController.userIdentifier)
            .store(in: &disposeBag)
                
//        items
//            .receive(on: DispatchQueue.main)
//            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
//            .sink { [weak self] items in
//                guard let self = self else { return }
//                guard let diffableDataSource = self.diffableDataSource else { return }
//                os_log("%{public}s[%{public}ld], %{public}s: items did change", ((#file as NSString).lastPathComponent), #line, #function)
//
//                var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
//                snapshot.appendSections([.main])
//                snapshot.appendItems(items)
//                
//                if let currentState = self.stateMachine.currentState {
//                    switch currentState {
//                    case is State.Reloading, is State.Idle, is State.LoadingMore, is State.Fail:
//                        snapshot.appendItems([.bottomLoader], toSection: .main)
//                    case is State.NotAuthorized:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .notAuthorized))], toSection: .main)
//                    case is State.Blocked:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .blocked))], toSection: .main)
//                    case is State.Suspended:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .suspended))], toSection: .main)
//                    case is State.NoMore:
//                        if items.isEmpty {
//                            snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .noTweetsFound))], toSection: .main)
//                        }
//                    default:
//                        break
//                    }
//                }
//                
//                diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
//            }
//            .store(in: &disposeBag)
//        
//        tweetIDs
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] ids in
//                guard let self = self else { return }
//                self.fetchedResultsController.fetchRequest.predicate = Tweet.predicate(idStrs: ids)
//                do {
//                    try self.fetchedResultsController.performFetch()
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewModel {
    
    enum UserTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidUserID
        case invalidAnchorToLoadMore
    }
    
//    func fetchLatest() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
//        }
//        guard let userID = self.userID.value, !userID.isEmpty else {
//            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
//        }
//
//        return context.apiService.twitterUserTimeline(count: 20, userID: userID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
//    }
//
//    func loadMore() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
//        }
//        guard let userID = self.userID.value, !userID.isEmpty else {
//            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
//        }
//        guard let oldestTweetID = tweetIDs.value.last else {
//            return Fail(error: UserTimelineError.invalidAnchorToLoadMore).eraseToAnyPublisher()
//        }
//
//        let maxID = oldestTweetID
//        return context.apiService.twitterUserTimeline(count: 20, userID: userID, maxID: maxID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
//    }
    
}
