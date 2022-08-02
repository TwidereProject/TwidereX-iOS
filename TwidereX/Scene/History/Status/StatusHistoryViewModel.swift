//
//  StatusHistoryViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import TwidereCore
import TwidereUI

final class StatusHistoryViewModel {
    
    let logger = Logger(subsystem: "StatusHistoryViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let historyFetchedResultsController: HistoryFetchedResultsController
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<HistorySection, HistoryItem>?

    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        self.historyFetchedResultsController = HistoryFetchedResultsController(managedObjectContext: context.managedObjectContext)
        // end init
        
        historyFetchedResultsController.predicate = History.statusPredicate(acct: authContext.authenticationContext.acct)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
