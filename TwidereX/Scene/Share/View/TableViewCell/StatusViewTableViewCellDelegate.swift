//
//  StatusViewTableViewCellDelegate.swift
//  StatusViewTableViewCellDelegate
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI
import MetaTextArea
import Meta

// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(statusView"
// sourcery: replaceWith = "delegate?.tableViewCell(self, statusView: statusView"
protocol StatusViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var delegate: StatusViewTableViewCellDelegate? { get }
    var statusView: StatusView { get }
}

// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
protocol StatusViewTableViewCellDelegate: AutoGenerateProtocolDelegate {
    // sourcery:inline:StatusViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    // sourcery:inline:StatusViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    // sourcery:end
}
