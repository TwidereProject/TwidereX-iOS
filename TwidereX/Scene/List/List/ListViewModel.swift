//
//  ListViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import TwidereCore
import GameplayKit

class ListViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let kind: Kind
    let fetchedResultController: ListRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ListSection, ListItem>?
    
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
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
        kind: Kind
    ) {
        self.context = context
        self.kind = kind
        self.fetchedResultController = ListRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init

        Task {
            let _userIdentifer: UserIdentifier? = await context.managedObjectContext.perform {
                guard let user = kind.user?.object(in: context.managedObjectContext) else { return nil }
                return UserIdentifier(object: user)
            }
            guard let userIdentifer = _userIdentifer else { return }
            
            self.fetchedResultController.userIdentifier = userIdentifer
            await self.stateMachine.enter(State.Reloading.self)
        }   // end Task
    }
    
}


extension ListViewModel {
    enum Kind {
        case none       // disabled
        case owned(user: UserRecord)
        case subscribed(user: UserRecord)
        case listed(user: UserRecord)
        
        var user: UserRecord? {
            switch self {
            case .none:                     return nil
            case .owned(let user):          return user
            case .subscribed(let user):     return user
            case .listed(let user):         return user
            }
        }
    }
}
