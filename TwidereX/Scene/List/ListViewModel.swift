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

class ListViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let kind: Kind
    let twitterUserOwnedListViewModel: TwitterUserOwnedListViewModel
    @Published var user: UserRecord?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ListSection, ListItem>?
    
    init(
        context: AppContext,
        kind: Kind,
        user: User
    ) {
        self.context = context
        self.kind = kind
        self.twitterUserOwnedListViewModel = TwitterUserOwnedListViewModel(context: context)
        // end init
        
        switch kind {
        case .lists:
            $user
                .map { record in
                    guard case let .twitter(record) = record else { return nil }
                    return record
                }
                .assign(to: &twitterUserOwnedListViewModel.$user)
        case .listed:
            break
        }
        
        switch user {
        case .me:
            context.authenticationService.$activeAuthenticationContext
                .asyncMap { authenticationContext -> UserRecord? in
                    guard let user = authenticationContext?.user(in: context.managedObjectContext) else { return nil }
                    return user.asRecord
                }
                .assign(to: &$user)
        case .user(let record):
            self.user = record
        }
    }
    
}

extension ListViewModel {
    enum Kind {
        case lists
        case listed
    }
    
    enum User {
        case me
        case user(UserRecord)
    }
}
