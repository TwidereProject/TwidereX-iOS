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
    
    @Published var title: String?
    @Published var isDeleted = false
    
    init(
        context: AppContext,
        list: ListRecord
    ) {
        self.context = context
        self.list = list
        self.fetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        // bind userIdentifier
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &fetchedResultController.$userIdentifier)
        
        // bind titile
        if let object = list.object(in: context.managedObjectContext) {
            switch object {
            case .twitter(let list):
                list.publisher(for: \.name)
                    .map { $0 as String? }
                    .assign(to: &$title)
            case .mastodon(let list):
                list.publisher(for: \.title)
                    .map { $0 as String? }
                    .assign(to: &$title)
            }
        }
        
        // listen delete event
        ManagedObjectObserver.observe(context: context.managedObjectContext)
            .sink(receiveCompletion: { completion in
                // do nohting
            }, receiveValue: { [weak self] changes in
                guard let self = self else { return }
                
                let objectIDs: [NSManagedObjectID] = changes.changeTypes.compactMap { changeType in
                    guard case let .delete(object) = changeType else { return nil }
                    return object.objectID
                }
                
                let isDeleted = objectIDs.contains(list.objectID)
                self.isDeleted = isDeleted
            })
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
