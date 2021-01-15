//
//  AccountListViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class AccountListViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<AccountListSection, Item>!
    var items = CurrentValueSubject<[Item], Never>([])
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        context.authenticationService.authenticationIndexes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationIndexes in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<AccountListSection, Item>()
                snapshot.appendSections([.main])
                for authenticationIndex in authenticationIndexes {
                    if let twitterUser = authenticationIndex.twitterAuthentication?.twitterUser {
                        let item = Item.twitterUser(objectID: twitterUser.objectID)
                        snapshot.appendItems([item], toSection: .main)
                    }
                }
                diffableDataSource.defaultRowAnimation = .none
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
