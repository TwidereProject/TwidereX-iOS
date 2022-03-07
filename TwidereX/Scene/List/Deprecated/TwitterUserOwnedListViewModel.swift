//
//  TwitterUserOwnedListViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreDataStack
import TwidereCore
import GameplayKit

final class TwitterUserOwnedListViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultController: TwitterListRecordFetchedResultController
    @Published var user: ManagedObjectRecord<TwitterUser>?
    
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
    
    init(context: AppContext) {
        self.context = context
        self.fetchedResultController = TwitterListRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        
        // trigger reload automatically
        $user
            .removeDuplicates()
            .receive(on: DispatchQueue.main)    // dispatch the @Published event on the next RunLoop
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.stateMachine.enter(State.Reloading.self)
                }
            }
            .store(in: &disposeBag)
    }
    
}
