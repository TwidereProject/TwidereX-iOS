//
//  DataSourceProvider+UITableViewDelegate.swift
//  DataSourceProvider+UITableViewDelegate
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Photos

extension UITableViewDelegate where Self: DataSourceProvider & AuthContextProvider {

    func aspectTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): indexPath: \(indexPath.debugDescription)")
        
        // TODO: tweak cell selection background color
        // let cell = tableView.cellForRow(at: indexPath)
        // cell?.backgroundColor = .red
        
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: indexPath)
            guard let item = await item(from: source) else {
                return
            }
            switch item {
            case .status(let status):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    kind: .status(status)
                )
            case .user(let user):
                await DataSourceFacade.coordinateToProfileScene(
                    provider: self,
                    user: user
                )
            case .notification(let notification):
                switch notification {
                case .twitter(let status):
                    await DataSourceFacade.coordinateToStatusThreadScene(
                        provider: self,
                        kind: .status(.twitter(record: status))
                    )
                case .mastodon(let notification):
                    let managedObjectContext = self.context.managedObjectContext
                    guard let object = notification.object(in: managedObjectContext) else {
                        assertionFailure()
                        return
                    }
                    if let status = object.status {
                        await DataSourceFacade.coordinateToStatusThreadScene(
                            provider: self,
                            kind: .status(.mastodon(record: status.asRecrod))
                        )
                    } else {
                        await DataSourceFacade.coordinateToProfileScene(
                            provider: self,
                            user: .mastodon(record: object.account.asRecrod)
                        )
                    }
                }
            }   // end switch
        }   // end Task
    }   // end func
    
}

extension UITableViewDelegate where Self: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController {
    
    func aspectTableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        return nil
    }
    
    func aspectTableView(
        _ tableView: UITableView,
        previewForHighlightingContextMenuWithConfiguration
        configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        return aspectTableView(tableView, configuration: configuration)
    }
    
    func aspectTableView(
        _ tableView: UITableView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        return aspectTableView(tableView, configuration: configuration)
    }
    
    private func aspectTableView(
        _ tableView: UITableView,
        configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return nil
    }
        
    func aspectTableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }   // end func
    
}
