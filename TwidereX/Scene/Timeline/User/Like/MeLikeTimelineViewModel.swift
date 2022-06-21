//
//  MeLikeTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-15.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

final class MeLikeTimelineViewModel: UserLikeTimelineViewModel {
    
    init(context: AppContext) {
        let timelineContext = StatusFetchViewModel.Timeline.Kind.UserTimelineContext(
            timelineKind: .like,
            userIdentifier: nil
        )
        super.init(
            context: context,
            timelineContext: timelineContext
        )
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &timelineContext.$userIdentifier)
    }

}
