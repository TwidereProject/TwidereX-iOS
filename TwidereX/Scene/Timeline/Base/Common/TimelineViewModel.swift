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

class TimelineViewModel: TimelineViewModelDriver {
    
    let logger = Logger(subsystem: "TimelineViewModel", category: "ViewModel")

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    let now = Date()
    
    // input
    let context: AppContext
    let kind: StatusFetchViewModel.Timeline.Kind
    let feedFetchedResultsController: FeedFetchedResultsController
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    
    @Published var enableAutoFetchLatest = false
    @Published var isRefreshControlEnabled = true
    @Published var isFloatyButtonDisplay = true
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?
    
    // output
    // @Published var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    // bottom loader
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Reloading(viewModel: self),
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
        kind: StatusFetchViewModel.Timeline.Kind
    ) {
        self.context  = context
        self.kind = kind
        self.feedFetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
    }
    
}

extension TimelineViewModel {
    
    @MainActor
    private func prepend(result: StatusFetchViewModel.Result) async {
        switch result {
        case .twitter(let array):
            let statusIDs = array.map { $0.idStr }
            statusRecordFetchedResultController.twitterStatusFetchedResultController.prepend(statusIDs: statusIDs)
        case .twitterV2(let array):
            let statusIDs = array.map { $0.id }
            statusRecordFetchedResultController.twitterStatusFetchedResultController.prepend(statusIDs: statusIDs)
        case .mastodon(let array):
            let statusIDs = array.map { $0.id }
            statusRecordFetchedResultController.mastodonStatusFetchedResultController.prepend(statusIDs: statusIDs)
        }
    }

    // load top
    @MainActor
    func loadLatest() async {
        isLoadingLatest = true
        defer {
            isLoadingLatest = false
        }
        
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return }
        let fetchContext = StatusFetchViewModel.Timeline.FetchContext(
            managedObjectContext: context.managedObjectContext,
            authenticationContext: authenticationContext,
            kind: kind,
            position: {
                switch kind {
                case .home:
                    let managedObjectContext = context.managedObjectContext
                    let anchor: StatusRecord? = {
                        guard let record = feedFetchedResultsController.records.first else { return nil }
                        guard let feed = record.object(in: managedObjectContext) else { return nil }
                        return feed.statusObject?.asRecord
                    }()
                    return .top(anchor: anchor)
                case .public, .hashtag, .list:
                    return .top(anchor: statusRecordFetchedResultController.records.first)
                case .search:
                    assertionFailure("do not support refresh for search")
                    return .top(anchor: nil)
                case .user:
                    // FIXME: use anchor with minID or reset the data source
                    // the like timeline gap may missing
                    return .top(anchor: nil)
                }
            }(),
            filter: StatusFetchViewModel.Timeline.Filter(rule: .empty)
        )

        do {
            let input = try await StatusFetchViewModel.Timeline.prepare(fetchContext: fetchContext)
            let output = try await StatusFetchViewModel.Timeline.fetch(
                api: context.apiService,
                input: input
            )
            switch kind {
            case .home:
                break
            case .public, .hashtag, .list, .search, .user:
                await prepend(result: output.result)
            }
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    

    
}
