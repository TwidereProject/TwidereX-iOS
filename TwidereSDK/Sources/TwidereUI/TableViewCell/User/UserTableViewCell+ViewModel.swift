//
//  UserTableViewCell+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack
import TwidereCore

extension UserTableViewCell {
    public final class ViewModel {
        public let user: UserObject
        public let me: UserObject?
        public let notification: NotificationObject?
        public let listMembershipViewModel: ListMembershipViewModel?
        
        public init(
            user: UserObject,
            me: UserObject?,
            notification: NotificationObject?,
            listMembershipViewModel: ListMembershipViewModel?
        ) {
            self.user = user
            self.me = me
            self.notification = notification
            self.listMembershipViewModel = listMembershipViewModel
        }
    }
    
    public func configure(
        viewModel: ViewModel,
        delegate: UserViewTableViewCellDelegate?
    ) {
        userView.configure(
            user: viewModel.user,
            me: viewModel.me,
            notification: viewModel.notification,
            listMembershipViewModel: viewModel.listMembershipViewModel
        )
        
        self.delegate = delegate
    }
    
}
