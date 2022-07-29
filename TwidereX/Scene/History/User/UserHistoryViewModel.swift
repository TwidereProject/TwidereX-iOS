//
//  UserHistoryViewModel.swift
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

final class UserHistoryViewModel {
    
    let logger = Logger(subsystem: "UserHistoryViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    
    // output
    // var diffableDataSource: UITableViewDiffableDataSource<NotificationSection, NotificationItem>?
    // var didLoadLatest = PassthroughSubject<Void, Never>()

    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        // end init
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
