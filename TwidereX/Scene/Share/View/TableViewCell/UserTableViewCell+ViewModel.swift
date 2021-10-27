//
//  UserTableViewCell+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import UIKit
import CoreDataStack

extension UserTableViewCell {
    final class ViewModel {
        let user: UserObject
        let me: UserObject?
        
        init(
            user: UserObject,
            me: UserObject?
        ) {
            self.user = user
            self.me = me
        }
    }
    
    // TODO: add delegate
    func configure(
        viewModel: ViewModel
    ) {
        userView.configure(
            user: viewModel.user,
            me: viewModel.me
        )
    }
    
}
