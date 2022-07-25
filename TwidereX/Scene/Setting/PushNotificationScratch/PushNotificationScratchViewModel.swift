//
//  PushNotificationScratchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import TwidereCore

final class PushNotificationScratchViewModel: ObservableObject {
    
    // input
    let context: AppContext
    
    @Published var isRandomNotification = true
    @Published var notificationID = ""
    
    @Published var accounts: [UserObject]
    @Published var activeAccountIndex: Int = 0
    
    // output
    
    init(context: AppContext) {
        self.context = context
        // end init
        
        accounts = context.authenticationService.authenticationIndexes.compactMap { $0.user }
    }
    
}
