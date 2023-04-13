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
// sourcery: replaceWith = "statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel"
public protocol StatusViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate? { get }
}

// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
public protocol StatusViewTableViewCellDelegate: AutoGenerateProtocolDelegate {
    // sourcery:inline:StatusViewTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, userAvatarButtonDidPressed user: UserRecord)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, textViewDidSelectMeta meta: Meta)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel, previewActionContext: ContextMenuInteractionPreviewActionContext)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, pollVoteActionForViewModel pollViewModel: PollView.ViewModel)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, pollUpdateIfNeedsForViewModel pollViewModel: PollView.ViewModel)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, pollViewModel: PollView.ViewModel, pollOptionDidSelectForViewModel optionViewModel: PollOptionView.ViewModel)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, statusMetricViewModel: StatusMetricView.ViewModel, statusMetricButtonDidPressed action: StatusMetricView.Action)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, statusToolbarViewModel: StatusToolbarView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action)
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, viewHeightDidChange: Void)
    // sourcery:end
}

// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
public extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    // sourcery:inline:StatusViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func statusView(_ viewModel: StatusView.ViewModel, userAvatarButtonDidPressed user: UserRecord) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, userAvatarButtonDidPressed: user)
    }

    func statusView(_ viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, toggleContentDisplay: isReveal)
    }

    func statusView(_ viewModel: StatusView.ViewModel, textViewDidSelectMeta meta: Meta) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, textViewDidSelectMeta: meta)
    }

    func statusView(_ viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, previewActionForMediaViewModel: mediaViewModel)
    }

    func statusView(_ viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel, previewActionContext: ContextMenuInteractionPreviewActionContext) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, previewActionForMediaViewModel: mediaViewModel, previewActionContext: previewActionContext)
    }

    func statusView(_ viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, toggleContentWarningOverlayDisplay: isReveal)
    }

    func statusView(_ viewModel: StatusView.ViewModel, pollVoteActionForViewModel pollViewModel: PollView.ViewModel) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, pollVoteActionForViewModel: pollViewModel)
    }

    func statusView(_ viewModel: StatusView.ViewModel, pollUpdateIfNeedsForViewModel pollViewModel: PollView.ViewModel) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, pollUpdateIfNeedsForViewModel: pollViewModel)
    }

    func statusView(_ viewModel: StatusView.ViewModel, pollViewModel: PollView.ViewModel, pollOptionDidSelectForViewModel optionViewModel: PollOptionView.ViewModel) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, pollViewModel: pollViewModel, pollOptionDidSelectForViewModel: optionViewModel)
    }

    func statusView(_ viewModel: StatusView.ViewModel, statusMetricViewModel: StatusMetricView.ViewModel, statusMetricButtonDidPressed action: StatusMetricView.Action) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, statusMetricViewModel: statusMetricViewModel, statusMetricButtonDidPressed: action)
    }

    func statusView(_ viewModel: StatusView.ViewModel, statusToolbarViewModel: StatusToolbarView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, statusToolbarViewModel: statusToolbarViewModel, statusToolbarButtonDidPressed: action)
    }

    func statusView(_ viewModel: StatusView.ViewModel, viewHeightDidChange: Void) {
        statusViewTableViewCellDelegate?.tableViewCell(self, viewModel: viewModel, viewHeightDidChange: viewHeightDidChange)
    }
    // sourcery:end
}
