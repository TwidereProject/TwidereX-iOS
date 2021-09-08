//
//  DataSourceFacade+StatusTableViewCellDelegate.swift
//  DataSourceFacade+StatusTableViewCellDelegate
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension StatusTableViewCellDelegate where Self: DataSourceProvider {
    func statusTableViewCell(_ cell: StatusTableViewCell, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        // TODO:
    }
    
    func statusTableViewCell(
        _ cell: StatusTableViewCell,
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
            switch item {
            case .status(let status):
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
            }   // end switch item
        }   // end Task
    }   // end func
}
