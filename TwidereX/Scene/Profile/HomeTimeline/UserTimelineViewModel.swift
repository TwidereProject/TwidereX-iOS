//
//  UserTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import AlamofireImage

class UserTimelineViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "UserTimelineViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var userIdentifier: UserIdentifier?
    
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
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
