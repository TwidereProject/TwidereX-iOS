//
//  DataSourceProvider+MediaInfoDescriptionViewDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextArea
import TwidereCommon
import TwidereCore
import TwidereUI
import AppShared

extension MediaInfoDescriptionViewDelegate where Self: DataSourceProvider {
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarButtonDidPressed button: UIButton) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
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
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, contentTextViewDidPressed textView: MetaTextAreaView) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
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
            default:
                assertionFailure()
            }
        }
    }
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
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
}
