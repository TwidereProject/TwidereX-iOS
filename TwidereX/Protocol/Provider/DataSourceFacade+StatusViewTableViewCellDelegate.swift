//
//  DataSourceFacade+StatusViewTableViewCellDelegate.swift
//  DataSourceFacade+StatusViewTableViewCellDelegate
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

// MARK: - header
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        headerDidPressed header: UIView
    ) {
        
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
        
    }

}

// MARK: - media
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        mediaGridContainerView containerView: MediaGridContainerView,
        didTapMediaView mediaView: MediaView,
        at index: Int
    ) {
        // TODO:
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        quoteStatusView: StatusView,
        mediaGridContainerView containerView: MediaGridContainerView,
        didTapMediaView mediaView: MediaView,
        at index: Int
    ) {
        
    }
}

// MARK: - toolbar
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        statusView: StatusView,
        statusToolbar: StatusToolbar,
        actionDidPressed action: StatusToolbar.Action
    ) {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
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
            
            switch action {
            case .repost:
                do {
                    try await DataSourceFacade.responseToStatusRepostAction(
                        provider: self,
                        status: status,
                        authenticationContext: authenticationContext
                    )
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update repost failure: \(error.localizedDescription)")
                }
            case .like:
                do {
                    try await DataSourceFacade.responseToStatusLikeAction(
                        provider: self,
                        status: status,
                        authenticationContext: authenticationContext
                    )
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update like failure: \(error.localizedDescription)")
                }
            default:
                break
            }   // end switch action
        }   // end Task
    }   // end func
}
