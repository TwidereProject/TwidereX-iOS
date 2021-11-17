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
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>!
    var items = CurrentValueSubject<[UserItem], Never>([])
    
    init(context: AppContext) {
        self.context = context
        super.init()
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
