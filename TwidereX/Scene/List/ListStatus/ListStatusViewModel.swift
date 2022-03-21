//
//  ListStatusViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import AlamofireImage
import TwidereCore

class ListStatusViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "ListStatusViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let fetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    @Published var list: ListRecord?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    
    @Published var title: String?
    
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(
        context: AppContext,
        list: ListRecord
    ) {
        self.context = context
        self.list = list
        self.fetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &fetchedResultController.$userIdentifier)
        
        $list
            .asyncMap { [weak self] record in
                guard let self = self else { return nil }
                guard let list = record?.object(in: context.managedObjectContext) else { return nil }
                switch list {
                case .twitter(let object):      return object.name
                case .mastodon(let object):     return object.title
                }
            }
            .assign(to: &$title)
            
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
