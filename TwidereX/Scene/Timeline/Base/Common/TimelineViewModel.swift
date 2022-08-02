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
import func QuartzCore.CACurrentMediaTime

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
    
    @Published private(set) var timelineRefreshInterval = UserDefaults.shared.timelineRefreshInterval
    @Published private(set) var preferredTimelineResetToTop = UserDefaults.shared.preferredTimelineResetToTop
    
    // output
    let didLoadLatest = PassthroughSubject<Void, Never>()
    
    // auto fetch
    private var autoFetchLatestActionTime = CACurrentMediaTime()
    let autoFetchLatestAction = PassthroughSubject<Void, Never>()
    let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
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
        super.init()
        // end init
        
        UserDefaults.shared.publisher(for: \.timelineRefreshInterval)
            .removeDuplicates()
            .assign(to: &$timelineRefreshInterval)
        
        UserDefaults.shared.publisher(for: \.preferredTimelineResetToTop)
            .removeDuplicates()
            .assign(to: &$preferredTimelineResetToTop)
        
        timestampUpdatePublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.enableAutoFetchLatest else { return }
                let now = CACurrentMediaTime()
                let elapse = now - self.autoFetchLatestActionTime
                guard elapse > self.timelineRefreshInterval.seconds else {
                    let remains = self.timelineRefreshInterval.seconds - elapse
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): (\(String(describing: self)) auto fetch in \(remains, format: .fixed(precision: 2))s")
                    return
                }
                self.autoFetchLatestActionTime = now
                self.autoFetchLatestAction.send()
            }
            .store(in: &disposeBag)
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
        guard !isLoadingLatest else {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip due to loading latest on flying")
            return
        }
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
            guard output.result.count != .zero else {
                throw AppError.implicit(.internal(reason: "empty results"))
            }
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
