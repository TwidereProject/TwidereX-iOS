//
//  UserMediaTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK

final class UserMediaTimelineViewModel: NSObject {
    
    let logger = Logger(subsystem: "UserMediaTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var userIdentifier: UserIdentifier?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<StatusMediaGallerySection, StatusItem>?

    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Idle(viewModel: self),
            State.Fail(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.NotAuthorized(viewModel: self),
            State.Blocked(viewModel: self),
            State.Suspended(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
//    lazy var stateMachinePublisher = CurrentValueSubject<State, Never>(State.Initial(viewModel: self))
//    let pagingTweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])      // paging use only. NOT for displaying
//    let tweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
//    let items = CurrentValueSubject<[Item], Never>([])
    
    init(context: AppContext) {
        self.context = context
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        $userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
//        self.fetchedResultsController.delegate = self
//
//        items.eraseToAnyPublisher()
//            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)      // fix scroll position jumping issue
//            .sink { [weak self] items in
//                guard let self = self else { return }
//                guard let diffableDataSource = self.diffableDataSource else { return }
//                os_log("%{public}s[%{public}ld], %{public}s: items did change", ((#file as NSString).lastPathComponent), #line, #function)
//
//                var snapshot = NSDiffableDataSourceSnapshot<MediaSection, Item>()
//                snapshot.appendSections([.main, .footer])
//                snapshot.appendItems(items, toSection: .main)
//                if let currentState = self.stateMachine.currentState {
//                    switch currentState {
//                    case is State.Reloading, is State.Idle, is State.LoadingMore, is State.Fail:
//                        snapshot.appendItems([.bottomLoader], toSection: .footer)
//                    case is State.NotAuthorized:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .notAuthorized))], toSection: .footer)
//                    case is State.Blocked:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .blocked))], toSection: .footer)
//                    case is State.Suspended:
//                        snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .suspended))], toSection: .footer)
//                    case is State.NoMore:
//                        if items.isEmpty {
//                            snapshot.appendItems([.emptyStateHeader(attribute: .init(reason: .noTweetsFound))], toSection: .footer)
//                        }
//                    default:
//                        break
//                    }
//                }
//
//                // set animatingDifferences to false fix scroll position jumping issue
//                diffableDataSource.apply(snapshot, animatingDifferences: false)
//            }
//            .store(in: &disposeBag)
//
//        tweetIDs
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] ids in
//                guard let self = self else { return }
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//
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

extension UserMediaTimelineViewModel {
    
    enum UserTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidUserID
        case invalidAnchorToLoadMore
    }
    
//    func fetchLatest() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        guard let twitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
//        }
//        guard let userID = self.userID.value, !userID.isEmpty else {
//            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
//        }
//        
//        return context.apiService.twitterUserTimeline(count: 200, userID: userID, excludeReplies: false, twitterAuthenticationBox: twitterAuthenticationBox)
//    }
//    
//    func loadMore() -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        guard let twitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
//        }
//        guard let userID = self.userID.value, !userID.isEmpty else {
//            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
//        }
//        guard let maxID = pagingTweetIDs.value.last else {
//            return Fail(error: UserTimelineError.invalidAnchorToLoadMore).eraseToAnyPublisher()
//        }
//        
//        return context.apiService.twitterUserTimeline(count: 200, userID: userID, maxID: maxID, excludeReplies: false, twitterAuthenticationBox: twitterAuthenticationBox)
//    }
    
}
