//
//  UserProvider+SearchUserTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension SearchUserTableViewCellDelegate where Self: UserProvider {
    func userBriefInfoTableViewCell(_ cell: SearchUserTableViewCell, followActionButtonPressed button: FollowActionButton) {
        UserProviderFacade
            .toggleUserFriendship(provider: self, cell: cell)
            .sink { _ in
                // do nothing
            } receiveValue: { _ in
                // do nothing
            }
            .store(in: &disposeBag)
    }
}
