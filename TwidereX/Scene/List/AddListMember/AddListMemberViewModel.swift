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
    let list: ListRecord
    weak var listMembershipViewModelDelegate: ListMembershipViewModelDelegate?
    
    // output
    @Published var userIdentifier: UserIdentifier?
    
    init(
        context: AppContext,
        list: ListRecord
    ) {
        self.context = context
        self.list = list
        // end init
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &$userIdentifier)
    }
    
}
