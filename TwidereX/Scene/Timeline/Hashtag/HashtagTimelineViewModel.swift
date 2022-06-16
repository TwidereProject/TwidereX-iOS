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
        hashtag: String
    ) {
        super.init(
            context: context,
            kind: .hashtag(hashtag: hashtag)
        )
                
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
