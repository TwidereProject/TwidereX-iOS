//
//  ProfileHeaderViewModel.swift
//  ProfileHeaderViewModel
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine

final class ProfileHeaderViewModel: ObservableObject {
    
    // input
    let context: AppContext
    @Published var user: UserObject?
    
    init(context: AppContext) {
        self.context = context
    }
    
}
