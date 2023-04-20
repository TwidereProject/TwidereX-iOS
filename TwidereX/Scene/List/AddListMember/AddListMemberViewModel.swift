//
//  AddListMemberViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-22.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

final class AddListMemberViewModel {
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let list: ListRecord
    weak var listMembershipViewModelDelegate: ListMembershipViewModelDelegate?
    
    // output
    @Published var userIdentifier: UserIdentifier?
    
    init(
        context: AppContext,
        authContext: AuthContext,
        list: ListRecord
    ) {
        self.context = context
        self.authContext = authContext
        self.list = list
        // end init
        
        userIdentifier = authContext.authenticationContext.userIdentifier
    }
    
}
