//
//  MeProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final class MeProfileViewModel: ProfileViewModel {
    
    convenience init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.init(
            context: context,
            authContext: authContext,
            displayLikeTimeline: true
        )
        // end init
        
        self.user = authContext.authenticationContext.user(in: context.managedObjectContext)
    }

}
