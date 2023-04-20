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
    
    override init(
        context: AppContext,
        authContext: AuthContext
    ) {
        super.init(context: context,authContext: authContext)
        // end init
        
        self.user = authContext.authenticationContext.user(in: context.managedObjectContext)
    }

}
