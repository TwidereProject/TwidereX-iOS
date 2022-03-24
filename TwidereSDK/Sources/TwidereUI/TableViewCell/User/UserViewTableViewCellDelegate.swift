//
//  UserViewTableViewCellDelegate.swift
//  
//
//  Created by MainasuK on 2022-3-23.
//

import UIKit
import TwidereCommon

// sourcery: protocolName = "UserViewDelegate"
// sourcery: replaceOf = "userView(userView"
// sourcery: replaceWith = "delegate?.tableViewCell(self, userView: userView"
public protocol UserViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var delegate: UserViewTableViewCellDelegate? { get }
    var userView: UserView { get }
}


// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "UserViewDelegate"
// sourcery: replaceOf = "userView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
public protocol UserViewTableViewCellDelegate: AutoGenerateProtocolDelegate {
    // sourcery:inline:UserViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, userView: UserView, menuActionDidPressed action: UserView.MenuAction, menuButton button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, userView: UserView, friendshipButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, userView: UserView, membershipButtonDidPressed button: UIButton)
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
extension UserViewDelegate where Self: UserViewContainerTableViewCell {
    // sourcery:inline:UserViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func userView(_ userView: UserView, menuActionDidPressed action: UserView.MenuAction, menuButton button: UIButton) {
        delegate?.tableViewCell(self, userView: userView, menuActionDidPressed: action, menuButton: button)
    }

    func userView(_ userView: UserView, friendshipButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, userView: userView, friendshipButtonDidPressed: button)
    }

    func userView(_ userView: UserView, membershipButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, userView: userView, membershipButtonDidPressed: button)
    }
  
    // sourcery:end  
}
