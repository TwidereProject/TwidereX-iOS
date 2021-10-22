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
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var userIdentifier: UserIdentifier?
    
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
    
    init(context: AppContext) {
        self.context = context
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        $userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewModel {
    
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
