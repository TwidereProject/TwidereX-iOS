//
//  SearchUserViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
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
import TwidereUI

final class SearchUserViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "SearchUserViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let kind: Kind
    let userRecordFetchedResultController: UserRecordFetchedResultController
    let listMembershipViewModel: ListMembershipViewModel?
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = PassthroughSubject<Void, Never>()
    @Published var searchText = ""
    @Published var userIdentifier: UserIdentifier?

    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?
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

    init(
        context: AppContext,
        kind: SearchUserViewModel.Kind
    ) {
        self.context = context
        self.kind = kind
        self.userRecordFetchedResultController = UserRecordFetchedResultController(
            managedObjectContext: context.managedObjectContext
        )
        self.listMembershipViewModel = {
            guard case let .listMember(list) = kind else { return nil }
            return ListMembershipViewModel(api: context.apiService, list: list)
        }()
        // end init
        
        $searchText
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText)")
                Task {
                    await self.stateMachine.enter(SearchUserViewModel.State.Reset.self)                    
                }
            }
            .store(in: &disposeBag)
        
        $userIdentifier
            .assign(to: &userRecordFetchedResultController.$userIdentifier)
    
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchUserViewModel {
    enum Kind {
        case friendship
        case listMember(list: ListRecord)
    }
}
