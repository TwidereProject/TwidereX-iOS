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
import TwidereCore

final class FriendshipListViewModel: NSObject {
    
    let logger = Logger(subsystem: "FriendshipListViewModel", category: "ViewModel")
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let kind: Kind
    let userIdentifier: UserIdentifier
    let userRecordFetchedResultController: UserRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>!
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.PermissionDenied(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    @Published var isPermissionDenied = false
    
    init(
        context: AppContext,
        kind: Kind,
        userIdentifier: UserIdentifier      // identifier for friend list owner user
    ) {
        self.context = context
        self.kind = kind
        self.userIdentifier = userIdentifier
        self.userRecordFetchedResultController = UserRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        super.init()
        
        userRecordFetchedResultController.userIdentifier = userIdentifier   // the domain will be set
    }
    
    // convenience init for current active user
    convenience init?(
        context: AppContext,
        kind: Kind
    ) {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return nil }
        let userIdentifier = authenticationContext.userIdentifier
        
        self.init(
            context: context,
            kind: kind,
            userIdentifier: userIdentifier
        )
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension FriendshipListViewModel {
    typealias Kind = UserListFetchViewModel.FriendshipListKind
}
