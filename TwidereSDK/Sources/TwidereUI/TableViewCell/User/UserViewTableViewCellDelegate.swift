//
//  UserViewTableViewCellDelegate.swift
//  
//
//  Created by MainasuK on 2022-3-23.
//

import UIKit

// sourcery: protocolName = "UserViewDelegate"
// sourcery: replaceOf = "userView(viewModel"
// sourcery: replaceWith = "userViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel"
public protocol UserViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var userViewTableViewCellDelegate: UserViewTableViewCellDelegate? { get }
}


// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "UserViewDelegate"
// sourcery: replaceOf = "userView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
public protocol UserViewTableViewCellDelegate: AutoGenerateProtocolDelegate {
    // sourcery:inline:UserViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, viewModel: UserView.ViewModel, userAvatarButtonDidPressed user: UserRecord)
    func tableViewCell(_ cell: UITableViewCell, viewModel: UserView.ViewModel, menuActionDidPressed action: UserView.ViewModel.MenuAction)
    func tableViewCell(_ cell: UITableViewCell, viewModel: UserView.ViewModel, listMembershipButtonDidPressed user: UserRecord)
    func tableViewCell(_ cell: UITableViewCell, viewModel: UserView.ViewModel, followReqeustButtonDidPressed user: UserRecord, accept: Bool)
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
public extension UserViewDelegate where Self: UserViewContainerTableViewCell {
    // sourcery:inline:UserViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func userView(_ viewModel: UserView.ViewModel, userAvatarButtonDidPressed user: UserRecord) {
        userViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, userAvatarButtonDidPressed: user)
    }

    func userView(_ viewModel: UserView.ViewModel, menuActionDidPressed action: UserView.ViewModel.MenuAction) {
        userViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, menuActionDidPressed: action)
    }

    func userView(_ viewModel: UserView.ViewModel, listMembershipButtonDidPressed user: UserRecord) {
        userViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, listMembershipButtonDidPressed: user)
    }

    func userView(_ viewModel: UserView.ViewModel, followReqeustButtonDidPressed user: UserRecord, accept: Bool) {
        userViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, followReqeustButtonDidPressed: user, accept: accept)
    }
  
    // sourcery:end  
}
