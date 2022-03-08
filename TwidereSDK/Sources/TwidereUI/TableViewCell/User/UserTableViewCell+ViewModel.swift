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
    public final class ViewModel {
        public let user: UserObject
        public let me: UserObject?
        public let notification: NotificationObject?
        
        public init(
            user: UserObject,
            me: UserObject?,
            notification: NotificationObject?
        ) {
            self.user = user
            self.me = me
            self.notification = notification
        }
    }
    
    public func configure(
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
