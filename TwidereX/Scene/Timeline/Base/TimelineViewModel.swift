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
    let kind: Kind
    let fetchedResultsController: FeedFetchedResultsController
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
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
    
    init(
        context: AppContext,
        kind: Kind
    ) {
        self.context  = context
        self.kind = kind
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
    }
    
}

extension TimelineViewModel {
    enum Kind {
        case home
        case federated(local: Bool)
    }
}
