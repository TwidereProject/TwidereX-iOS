//
//  DataSourceProvider+StatusViewTableViewCellDelegate.swift
//
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AppShared
import TwidereComposeUI
import MetaTextArea
import Meta

// MARK: - header
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        headerDidPressed header: UIView
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                target: .repost,
                status: status
            )
        }
    }

}

// MARK: - avatar button
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        authorAvatarButtonDidPressed button: AvatarButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                target: .status,
                status: status
            )
        }
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        quoteStatusView: StatusView,
        authorAvatarButtonDidPressed button: AvatarButton
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                target: .quote,
                status: status
            )
        }
    }

}

// MARK: - spoiler
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, expandContentButtonDidPressed button: UIButton) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            try await DataSourceFacade.responseToExpandContentAction(
                provider: self,
                target: .status,
                status: status
            )
        }
    }
}

// MARK: - content
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.responseToMetaTextAreaView(
                provider: self,
                target: .status,
                status: status,
                metaTextAreaView: metaTextAreaView,
                didSelectMeta: meta
            )
        }
    }
    
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.responseToMetaTextAreaView(
                provider: self,
                target: .quote,
                status: status,
                metaTextAreaView: metaTextAreaView,
                didSelectMeta: meta
            )
        }
    }
}


// MARK: - media
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & MediaPreviewTransitionHostViewController {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        mediaGridContainerView containerView: MediaGridContainerView,
        didTapMediaView mediaView: MediaView,
        at index: Int
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToMediaPreviewScene(
                provider: self,
                target: .status,
                status: status,
                mediaPreviewContext: DataSourceFacade.MediaPreviewContext(
                    containerView: .mediaGridContainerView(containerView),
                    mediaView: mediaView,
                    index: index
                )
            )
        }
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        quoteStatusView: StatusView,
        mediaGridContainerView containerView: MediaGridContainerView,
        didTapMediaView mediaView: MediaView,
        at index: Int
    ) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToMediaPreviewScene(
                provider: self,
                target: .quote,
                status: status,
                mediaPreviewContext: DataSourceFacade.MediaPreviewContext(
                    containerView: .mediaGridContainerView(containerView),
                    mediaView: mediaView,
                    index: index
                )
            )
        }
    }
    
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            try await DataSourceFacade.responseToToggleMediaSensitiveAction(
                provider: self,
                target: .status,
                status: status
            )
        }
    }
}

// poll
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.responseToStatusPollOption(
                provider: self,
                target: .status,
                status: status,
                didSelectRowAt: indexPath
            )
        }
    }
    
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollVoteButtonDidPressed button: UIButton) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.responseToStatusPollOption(
                provider: self,
                target: .status,
                status: status,
                voteButtonDidPressed: button
            )
        }
    }
}

// MARK: - quote
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                return
            }
            
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.coordinateToStatusThreadScene(
                provider: self,
                target: .quote,
                status: status
            )
        }
    }
}


// MARK: - toolbar
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        statusToolbar: StatusToolbar,
        actionDidPressed action: StatusToolbar.Action,
        button: UIButton
    ) {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return }
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.responseToStatusToolbar(
                provider: self,
                status: status,
                action: action,
                sender: button,
                authenticationContext: authenticationContext
            )
        }   // end Task
    }   // end func
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        statusToolbar: StatusToolbar,
        menuActionDidPressed action: StatusToolbar.MenuAction,
        menuButton button: UIButton
    ) {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext else { return }
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            try await DataSourceFacade.responseToRemoveStatusAction(
                provider: self,
                target: .status,
                status: status,
                authenticationContext: authenticationContext
            )
        }   // end Task
        
    }

}

// MARK: - a11y
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {

    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, accessibilityActivate: Void) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                return
            }
            switch item {
            case .status(let status):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    target: .repost,    // keep repost wrapper
                    status: status
                )
            case .user(let user):
                await DataSourceFacade.coordinateToProfileScene(
                    provider: self,
                    user: user
                )
            case .notification(let notification):
                assertionFailure("TODO")
            }
        }
    }
    
}

