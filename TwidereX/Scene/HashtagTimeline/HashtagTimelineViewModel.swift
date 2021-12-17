//
//  HashtagTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit

final class HashtagTimelineViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "HashtagTimelineViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let hashtag: String
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Idle(viewModel: self),
            State.Reset(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(context: AppContext, hashtag: String) {
        self.context = context
        self.hashtag = hashtag
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        context.authenticationService.activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
}
