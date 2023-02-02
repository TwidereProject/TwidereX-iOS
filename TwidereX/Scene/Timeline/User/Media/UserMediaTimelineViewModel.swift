//
//  UserMediaTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

final class UserMediaTimelineViewModel: GridTimelineViewModel {

    init(
        context: AppContext,
        authContext: AuthContext,
        timelineContext: StatusFetchViewModel.Timeline.Kind.UserTimelineContext
    ) {
        super.init(
            context: context,
            authContext: authContext,
            kind: .user(userTimelineContext: timelineContext)
        )
        
        timelineContext.$userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}
