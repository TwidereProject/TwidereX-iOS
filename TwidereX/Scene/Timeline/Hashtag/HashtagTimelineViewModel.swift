//
//  HashtagTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

final class HashtagTimelineViewModel: ListTimelineViewModel {
    
    init(
        context: AppContext,
        authContext: AuthContext,
        hashtag: String
    ) {
        super.init(
            context: context,
            authContext: authContext,
            kind: .hashtag(hashtag: hashtag)
        )

        statusRecordFetchedResultController.userIdentifier = authContext.authenticationContext.userIdentifier
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
