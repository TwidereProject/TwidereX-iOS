//
//  StatusViewTableViewCellDelegate.swift
//  StatusViewTableViewCellDelegate
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore
import MetaTextArea
import Meta

// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(viewModel"
// sourcery: replaceWith = "delegate?.tableViewCell(self, viewModel: viewModel"
protocol StatusViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var delegate: StatusViewTableViewCellDelegate? { get }
    var viewModel: StatusView.ViewModel? { get }
}

// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
protocol StatusViewTableViewCellDelegate: AutoGenerateProtocolDelegate {
    // sourcery:inline:StatusViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, viewHeightDidChange: Void)
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    // sourcery:inline:StatusViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func statusView(_ viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool) {
        delegate?.tableViewCell(self, viewModel: viewModel, toggleContentDisplay: isReveal)
    }

    func statusView(_ viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel) {
        delegate?.tableViewCell(self, viewModel: viewModel, previewActionForMediaViewModel: mediaViewModel)
    }

    func statusView(_ viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool) {
        delegate?.tableViewCell(self, viewModel: viewModel, toggleContentWarningOverlayDisplay: isReveal)
    }

    func statusView(_ viewModel: StatusView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action) {
        delegate?.tableViewCell(self, viewModel: viewModel, statusToolbarButtonDidPressed: action)
    }

    func statusView(_ viewModel: StatusView.ViewModel, viewHeightDidChange: Void) {
        delegate?.tableViewCell(self, viewModel: viewModel, viewHeightDidChange: viewHeightDidChange)
    }
    // sourcery:end
}
