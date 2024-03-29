//
//  FriendshipListViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK

final class FriendshipListViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let userID: Twitter.Entity.V2.User.ID
    let friendshipLookupKind: APIService.FriendshipListKind
    let orderedTwitterUserFetchedResultsController: OrderedTwitterUserFetchedResultsController
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<FriendshipListSection, Item>!
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(context: AppContext, userID: Twitter.Entity.V2.User.ID, friendshipLookupKind: APIService.FriendshipListKind) {
        self.context = context
        self.userID = userID
        self.orderedTwitterUserFetchedResultsController = OrderedTwitterUserFetchedResultsController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        orderedTwitterUserFetchedResultsController.items
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<FriendshipListSection, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                if let currentState = self.stateMachine.currentState,
                   currentState is State.Loading || currentState is State.Idle || currentState is State.Fail {
                    snapshot.appendItems([.bottomLoader], toSection: .main)
                }
                
                // not animate when empty items fix loader first appear layout issue 
                diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty, completion: nil)
            }
            .store(in: &disposeBag)
    }
    
    // convenience init for current active user
    convenience init?(context: AppContext, friendshipLookupKind: APIService.FriendshipListKind) {
        guard let activeAuthenticationIndex = context.authenticationService.activeAuthenticationIndex.value else {
            return nil
        }
        switch activeAuthenticationIndex.platform {
        case .twitter:
            guard let userID = activeAuthenticationIndex.twitterAuthentication?.userID else {
                return nil
            }
            self.init(context: context, userID: userID)
        default:
            return nil
        }
    }
    
}
