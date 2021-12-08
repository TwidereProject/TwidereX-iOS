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

protocol StatusViewContainerTableViewCell: UITableViewCell {
    var delegate: StatusViewTableViewCellDelegate? { get }
    var statusView: StatusView { get }
}

// TODO: refactor with Stencil
protocol StatusViewTableViewCellDelegate: AnyObject {
    // header
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, headerDidPressed header: UIView)
    // avatar button
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    // content
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
    // media
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    // toolbar
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton)
}

// TODO: refactor with Stencil
// Protocol Extension
extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
        delegate?.tableViewCell(self, statusView: statusView, headerDidPressed: header)
    }
    
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        delegate?.tableViewCell(self, statusView: statusView, authorAvatarButtonDidPressed: button)
    }
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, authorAvatarButtonDidPressed: button)
    }
    
    func statusView(_ statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        delegate?.tableViewCell(self, statusView: statusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
    }
    
    func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
    }
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
    }
    
    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusToolbar: statusToolbar, actionDidPressed: action, button: button)
    }
    
}
