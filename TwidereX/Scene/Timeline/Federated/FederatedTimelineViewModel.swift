//
//  FederatedTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

final class FederatedTimelineViewModel: ListTimelineViewModel {
    
    init(
        context: AppContext,
        authContext: AuthContext,
        isLocal: Bool
    ) {
        super.init(
            context: context,
            authContext: authContext,
            kind: .public(isLocal: isLocal)
        )
        
        enableAutoFetchLatest = true
        switch authContext.authenticationContext {
        case .twitter:
            self.statusRecordFetchedResultController.userIdentifier = nil
        case .mastodon(let authenticationContext):
            self.statusRecordFetchedResultController.userIdentifier = .mastodon(.init(
                domain: authenticationContext.domain,
                id: authenticationContext.userID
            ))
        }
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
