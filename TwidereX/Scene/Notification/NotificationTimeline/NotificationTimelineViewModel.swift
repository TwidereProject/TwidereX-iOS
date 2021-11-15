//
//  NotificationTimelineVIewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import GameplayKit

final class NotificationTimelineViewModel {
    
    let logger = Logger(subsystem: "NotificationTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let scope: Scope
    let fetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<NotificationSection, NotificationItem>?
    var didLoadLatest = PassthroughSubject<Void, Never>()
    
    private(set) lazy var loadOldestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Loading(viewModel: self),
            LoadOldestState.Fail(viewModel: self),
            LoadOldestState.Idle(viewModel: self),
            LoadOldestState.NoMore(viewModel: self),
        ])
        stateMachine.enter(LoadOldestState.Initial.self)
        return stateMachine
    }()

    init(context: AppContext, scope: Scope) {
        self.context = context
        self.scope = scope
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
        context.authenticationService.activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                let emptyFeedPredicate = Feed.nonePredicate()
                guard let authenticationContext = authenticationContext else {
                    self.fetchedResultsController.predicate.value = emptyFeedPredicate
                    return
                }
                
                let predicate = NotificationTimelineViewModel.feedPredicate(
                    authenticationContext: authenticationContext,
                    scope: scope
                )
                self.fetchedResultsController.predicate.value = predicate
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NotificationTimelineViewModel {
    enum Scope {
        case all
        case mentions
    }
    
    static func feedPredicate(
        authenticationContext: AuthenticationContext,
        scope: Scope
    ) -> NSPredicate {
        let predicate: NSPredicate
        switch authenticationContext {
        case .twitter(let authenticationContext):
            let userID = authenticationContext.userID
            predicate = Feed.predicate(kind: .notification, acct: Feed.Acct.twitter(userID: userID))
        case .mastodon(let authenticationContext):
            let domain = authenticationContext.domain
            let userID = authenticationContext.userID
            predicate = {
                switch scope {
                case .all:
                    return Feed.predicate(kind: .notification, acct: Feed.Acct.mastodon(domain: domain, userID: userID))
                case .mentions:
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        Feed.predicate(kind: .notification, acct: Feed.Acct.mastodon(domain: domain, userID: userID)),
                        Feed.mastodonNotificationTypePredicate(type: .mention)
                    ])
                }
            }()
        }
        return predicate
    }
}
