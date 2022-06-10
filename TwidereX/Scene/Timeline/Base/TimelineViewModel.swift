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
    let kind: StatusFetchViewModel.Timeline.Kind
    let feedFetchedResultsController: FeedFetchedResultsController
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    @Published var isLoadingLatest = false
    @Published var lastAutomaticFetchTimestamp: Date?
    
    // output
    @MainActor
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
            position: .top,
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
            case .federated:
                await prepend(result: output.result)
            default:
                assertionFailure()
            }
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
    // load middle gap
    
    func loadMore(item: StatusItem) async {
        guard case let .feedLoader(record) = item else { return }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return }
        guard let diffableDataSource = await diffableDataSource else { return }
        var snapshot = diffableDataSource.snapshot()

        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(record.objectID)"

        guard let feed = record.object(in: managedObjectContext) else { return }
        guard let statusObject = feed.statusObject else { return }
        
        // keep transient property alive
        managedObjectContext.cache(feed, key: key)
        defer {
            managedObjectContext.cache(nil, key: key)
        }
        do {
            // update state
            try await managedObjectContext.performChanges {
                feed.update(isLoadingMore: true)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }

        // reconfigure item
        snapshot.reconfigureItems([item])
        await updateDataSource(snapshot: snapshot, animatingDifferences: true)

        // fetch data
        do {
            let fetchContext = StatusFetchViewModel.Timeline.FetchContext(
                managedObjectContext: managedObjectContext,
                authenticationContext: authenticationContext,
                kind: kind,
                position: .middle(anchor: statusObject.asRecord),
                filter: StatusFetchViewModel.Timeline.Filter(rule: .empty)
            )
            let input = try await StatusFetchViewModel.Timeline.prepare(fetchContext: fetchContext)
            let output = try await StatusFetchViewModel.Timeline.fetch(
                api: context.apiService,
                input: input
            )
            switch kind {
            case .home:
                break
            default:
                assertionFailure("only home timeline has gap")
            }
        } catch {
            do {
                // restore state
                try await managedObjectContext.performChanges {
                    feed.update(isLoadingMore: false)
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch more failure: \(error.localizedDescription)")
        }

        // reconfigure item again
        snapshot.reconfigureItems([item])
        await updateDataSource(snapshot: snapshot, animatingDifferences: true)
    }
    
}
