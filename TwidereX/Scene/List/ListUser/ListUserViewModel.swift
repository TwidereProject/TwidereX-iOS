//
//  ListUserViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-11.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit
import TwidereCore

final class ListUserViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "ListStatusViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let kind: Kind
    let fetchedResultController: UserRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?
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
        kind: Kind
    ) {
        self.context = context
        self.kind = kind
        self.fetchedResultController = UserRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        Task {
            let _userIdentifer: UserIdentifier? = await context.managedObjectContext.perform {
                guard let list = kind.list.object(in: context.managedObjectContext) else { return nil }
                return UserIdentifier(object: list.owner)
            }
            guard let userIdentifer = _userIdentifer else { return }
            
            self.fetchedResultController.userIdentifier = userIdentifer
            await self.stateMachine.enter(State.Reloading.self)
        }   // end Task
    }
    
}

extension ListUserViewModel {
    enum Kind {
        case members(list: ListRecord)
        case subscribers(list: ListRecord)
        
        var list: ListRecord {
            switch self {
            case .members(let list):        return list
            case .subscribers(let list):    return list
            }
        }
        
        var title: String {
            switch self {
            case .members:      return L10n.Scene.ListsDetails.Tabs.members
            case .subscribers:  return L10n.Scene.ListsDetails.Tabs.subscriber
            }
        }
    }
}
