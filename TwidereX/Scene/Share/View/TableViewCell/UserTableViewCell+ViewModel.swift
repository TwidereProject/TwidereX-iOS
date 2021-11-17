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
        let notification: NotificationObject?
        
        init(
            user: UserObject,
            me: UserObject?,
            notification: NotificationObject?
        ) {
            self.user = user
            self.me = me
            self.notification = notification
        }
    }
    
    // TODO: add delegate
    func configure(
        viewModel: ViewModel,
        delegate: UserTableViewCellDelegate?
    ) {
        userView.configure(
            user: viewModel.user,
            me: viewModel.me,
            notification: viewModel.notification
        )
        
        self.delegate = delegate
    }
    
}
