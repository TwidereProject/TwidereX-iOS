//
//  MeLikeTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation

final class MeLikeTimelineViewModel: UserLikeTimelineViewModel {
    
    override init(context: AppContext) {
        super.init(context: context)
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &$userIdentifier)
    }

}
