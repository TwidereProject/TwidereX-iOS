//
//  UserTweetsTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import UIKit
import Combine

final class UserTweetsTimelineViewModel: UserTimelineViewModel {
    
    // input
    let context: AppContext
    let uesrID = CurrentValueSubject<String?, Never>(nil)
    
    init(context: AppContext) {
        self.context = context
    }
    
}

extension UserTweetsTimelineViewModel {
    
    //    func fetch() {
    //
    //    }
}
