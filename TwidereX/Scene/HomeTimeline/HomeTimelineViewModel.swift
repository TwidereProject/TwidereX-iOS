//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import AlamofireImage
import Kingfisher
import DateToolsSwift
import ActiveLabel

final class HomeTimelineViewModel: NSObject {
    
    let logger = Logger(subsystem: "HomeTimelineViewModel", category: "ViewModel")

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let fetchedResultsController: FeedFetchedResultsController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    var didLoadLatest = PassthroughSubject<Void, Never>()

    // bottom loader
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
    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        context.authenticationService.activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                let emptyFeedPredicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: ""))
                guard let authenticationContext = authenticationContext else {
                    self.fetchedResultsController.predicate.value = emptyFeedPredicate
                    return
                }
                
                let predicate: NSPredicate
                switch authenticationContext {
                case .twitter(let authenticationContext):
                    let userID = authenticationContext.userID
                    predicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: userID))
                case .mastodon(let authenticationContext):
                    let domain = authenticationContext.domain
                    let userID = authenticationContext.userID
                    predicate = Feed.predicate(kind: .home, acct: Feed.Acct.mastodon(domain: domain, userID: userID))
                }
                self.fetchedResultsController.predicate.value = predicate
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
