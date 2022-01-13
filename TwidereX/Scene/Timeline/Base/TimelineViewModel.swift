//
//  TimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import GameplayKit
import TwidereCore

class TimelineViewModel {
    
    let logger = Logger(subsystem: "TimelineViewModel", category: "ViewModel")

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    let now = Date()
    
    // input
    let context: AppContext
    let kind: Feed.Kind
    let fetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    // bottom loader
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
    
    // UI
    @Published var needsSetupAvatarBarButtonItem = false
    
    init(
        context: AppContext,
        kind: Feed.Kind
    ) {
        self.context  = context
        self.kind = kind
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init

        context.authenticationService.activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                let emptyFeedPredicate = Feed.predicate(kind: .none, acct: .none, since: nil)
                guard let authenticationContext = authenticationContext else {
                    self.fetchedResultsController.predicate.value = emptyFeedPredicate
                    return
                }
                
                let predicate: NSPredicate
                switch authenticationContext {
                case .twitter(let authenticationContext):
                    predicate = Feed.predicate(
                        kind: .home,
                        acct: Feed.Acct.twitter(userID: authenticationContext.userID),
                        since: nil
                    )
                case .mastodon(let authenticationContext):
                    predicate = Feed.predicate(
                        kind: kind,
                        acct: Feed.Acct.mastodon(
                            domain: authenticationContext.domain,
                            userID: authenticationContext.userID
                        ),
                        since: kind != .home ? self.now : nil
                    )
                }
                self.fetchedResultsController.predicate.value = predicate
            }
            .store(in: &disposeBag)
    }
}
