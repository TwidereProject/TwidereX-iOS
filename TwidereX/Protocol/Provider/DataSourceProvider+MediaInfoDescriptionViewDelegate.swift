//
//  DataSourceProvider+MediaInfoDescriptionViewDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextArea
import MetaTextKit
import MetaLabel

extension MediaInfoDescriptionViewDelegate where Self: DataSourceProvider & AuthContextProvider {
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarButtonDidPressed button: UIButton) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard let status = await item.status(in: self.context.managedObjectContext) else {
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
            guard let status = await item.status(in: self.context.managedObjectContext) else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.coordinateToStatusThreadScene(
                provider: self,
                kind: .status(status)
            )
        }
    }
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, nameMetaLabelDidPressed metaLabel: MetaLabel) {
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
            guard let item = await item(from: source) else {
                return
            }
            guard let status = await item.status(in: self.context.managedObjectContext) else {
                assertionFailure("only works for status data provider")
                return
            }
            
            await DataSourceFacade.coordinateToStatusThreadScene(
                provider: self,
                kind: .status(status)
            )
        }
    }

    
//    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard let status = await item.status(in: self.context.managedObjectContext) else {
//                assertionFailure("only works for status data provider")
//                return
//            }
//
//            await DataSourceFacade.responseToStatusToolbar(
//                provider: self,
//                status: status,
//                action: action,
//                sender: button,
//                authenticationContext: authContext.authenticationContext
//            )
//        }   // end Task
//    }   // end func
    
//    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
//        assertionFailure("present UIAcitivityController directly")
//    }

}
