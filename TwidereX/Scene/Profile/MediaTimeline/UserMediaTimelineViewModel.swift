//
//  UserMediaTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK

final class UserMediaTimelineViewModel {
    
    let logger = Logger(subsystem: "UserMediaTimelineViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var userIdentifier: UserIdentifier?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<StatusMediaGallerySection, StatusItem>?
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Idle(viewModel: self),
            State.Fail(viewModel: self),
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
        // end init
        
        $userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
