//
//  CompositeListViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-7.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import TwidereCore

class CompositeListViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let kind: Kind
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    
    let ownedListViewModel: ListViewModel
    let subscribedListViewModel: ListViewModel
    let listedListViewModel: ListViewModel
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ListSection, ListItem>?
    
    init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        switch kind {
        case .lists:
            self.ownedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .owned(user: kind.user))
            self.subscribedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .subscribed(user: kind.user))
            self.listedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .none)
        case .listed:
            self.ownedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .none)
            self.subscribedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .none)
            self.listedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .listed(user: kind.user))
        }
        // end init
    }
    
}

extension CompositeListViewModel {
    enum Kind {
        case lists(UserRecord)
        case listed(UserRecord)
        
        var user: UserRecord {
            switch self {
            case .lists(let user):      return user
            case .listed(let user):     return user
            }
        }
    }
}
