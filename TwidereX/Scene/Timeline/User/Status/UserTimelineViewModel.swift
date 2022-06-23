//
//  UserTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

class UserTimelineViewModel: ListTimelineViewModel {
    
    @Published var userIdentifier: UserIdentifier?

    init(context: AppContext, timelineContext: StatusFetchViewModel.Timeline.Kind.UserTimelineContext) {
        super.init(context: context, kind: .user(userTimelineContext: timelineContext))
        
        timelineContext.$userIdentifier
            .assign(to: &$userIdentifier)
        
        $userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
