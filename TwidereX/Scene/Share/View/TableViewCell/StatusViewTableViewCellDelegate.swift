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
protocol StatusViewTableViewCellDelegate: AnyObject, AutoGenerateProtocolDelegate {
    // sourcery:inline:StatusViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, headerDidPressed header: UIView)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, expandContentButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollVoteButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, accessibilityActivate: Void)
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    // sourcery:inline:StatusViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
        delegate?.tableViewCell(self, statusView: statusView, headerDidPressed: header)
    }

    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        delegate?.tableViewCell(self, statusView: statusView, authorAvatarButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, authorAvatarButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, expandContentButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, expandContentButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        delegate?.tableViewCell(self, statusView: statusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
    }

    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
    }

    func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
    }

    func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: containerView, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
    }

    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
    }

    func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tableViewCell(self, statusView: statusView, pollTableView: tableView, didSelectRowAt: indexPath)
    }

    func statusView(_ statusView: StatusView, pollVoteButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, pollVoteButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusViewDidPressed: quoteStatusView)
    }

    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusToolbar: statusToolbar, actionDidPressed: action, button: button)
    }

    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusToolbar: statusToolbar, menuActionDidPressed: action, menuButton: button)
    }

    func statusView(_ statusView: StatusView, accessibilityActivate: Void) {
        delegate?.tableViewCell(self, statusView: statusView, accessibilityActivate: accessibilityActivate)
    }
    // sourcery:end
    
}
