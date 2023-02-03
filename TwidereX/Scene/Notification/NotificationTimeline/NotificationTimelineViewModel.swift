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
import MastodonSDK
import TwidereCore
import TwidereUI

final class NotificationTimelineViewModel {
    
    let logger = Logger(subsystem: "NotificationTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let scope: Scope
    let fetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    @Published public var viewLayoutFrame = ViewLayoutFrame()
    
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?

    // output
    var diffableDataSource: UITableViewDiffableDataSource<NotificationSection, NotificationItem>?
    var didLoadLatest = PassthroughSubject<Void, Never>()
    
    @MainActor private(set) lazy var loadOldestStateMachine: GKStateMachine = {
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

    init(
        context: AppContext,
        authContext: AuthContext,
        scope: Scope
    ) {
        self.context = context
        self.authContext = authContext
        self.scope = scope
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
        let predicate = NotificationTimelineViewModel.feedPredicate(
            scope: scope,
            authenticationContext: authContext.authenticationContext
        )
        self.fetchedResultsController.predicate = predicate
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension NotificationTimelineViewModel {
    
    enum Scope: Hashable {
        case twitter
        case mastodon(Mastodon.API.Notification.TimelineScope)
        
        var title: String {
            switch self {
            case .twitter:
                return L10n.Scene.Notification.Tabs.mentions
            case .mastodon(let timelineScope):
                switch timelineScope {
                case .all:      return L10n.Scene.Notification.Tabs.all
                case .mentions: return L10n.Scene.Notification.Tabs.mentions
                }
            }
        }
    }
    
    static func feedPredicate(
        scope: Scope,
        authenticationContext: AuthenticationContext
    ) -> NSPredicate {
        let predicate: NSPredicate
        switch (scope, authenticationContext) {
        case (.twitter, .twitter(let authenticationContext)):
            let userID = authenticationContext.userID
            predicate = Feed.predicate(
                kind: .notificationMentions,
                acct: Feed.Acct.twitter(userID: userID)
            )
        case (.mastodon(let timelineScope), .mastodon(let authenticationContext)):
            let domain = authenticationContext.domain
            let userID = authenticationContext.userID
            let kind: Feed.Kind = {
                switch timelineScope {
                case .all:          return .notificationAll
                case .mentions:     return .notificationMentions
                }
            }()
            return Feed.predicate(
                kind: kind,
                acct: Feed.Acct.mastodon(
                    domain: domain,
                    userID: userID
                )
            )
        default:
            assertionFailure()
            predicate = Feed.nonePredicate()
        }
        return predicate
    }

}
