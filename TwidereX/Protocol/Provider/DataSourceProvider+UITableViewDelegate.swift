//
//  DataSourceProvider+UITableViewDelegate.swift
//  DataSourceProvider+UITableViewDelegate
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

extension UITableViewDelegate where Self: DataSourceProvider {

    func aspectTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): indexPath: \(indexPath.debugDescription)")
        Task {
            let source = DataSourceItem.Source(tableViewCell: nil, indexPath: indexPath)
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

extension UITableViewDelegate where Self: DataSourceProvider & MediaPreviewTransitionHostViewController {

    func aspectTableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let cell = tableView.cellForRow(at: indexPath) as? StatusViewContainerTableViewCell else { return nil }
        
        // TODO:
        // this must call before check `isContentWarningOverlayDisplay`. otherwise, will get BadAccess exception
        let mediaViews = cell.statusView.mediaGridContainerView.mediaViews
        
        if cell.statusView.mediaGridContainerView.viewModel.isContentWarningOverlayDisplay == true {
           return nil
        }
        
        for (i, mediaView) in mediaViews.enumerated() {
            let pointInMediaView = mediaView.convert(point, from: tableView)
            guard mediaView.point(inside: pointInMediaView, with: nil) else {
                continue
            }
            guard let image = mediaView.thumbnail(),
                  let assetURLString = mediaView.configuration?.assetURL,
                  let assetURL = URL(string: assetURLString),
                  let resourceType = mediaView.configuration?.resourceType
            else {
                // not provide preview unless thumbnail ready
                return nil
            }
            
            let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(aspectRatio: image.size, thumbnail: image)
            
            let configuration = TimelineTableViewCellContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
                if UIDevice.current.userInterfaceIdiom == .pad && mediaViews.count == 1 {
                    return nil
                }
                let previewProvider = ContextMenuImagePreviewViewController()
                previewProvider.viewModel = contextMenuImagePreviewViewModel
                return previewProvider
                
            } actionProvider: { _ -> UIMenu? in
                return UIMenu(
                    title: "",
                    image: nil,
                    identifier: nil,
                    options: [],
                    children: [
                        UIAction(
                            title: L10n.Common.Controls.Actions.save,
                            image: UIImage(systemName: "square.and.arrow.down"),
                            attributes: [],
                            state: .off
                        ) { [weak self] _ in
                            guard let self = self else { return }
                            Task {
                                let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
                                
                                do {
                                    impactFeedbackGenerator.impactOccurred()
                                    try await self.context.photoLibraryService.save(
                                        source: .remote(url: assetURL),
                                        resourceType: resourceType
                                    )
                                    self.context.photoLibraryService.presentSuccessNotification()
                                    notificationFeedbackGenerator.notificationOccurred(.success)
                                } catch {
                                    self.context.photoLibraryService.presentFailureNotification(error: error)
                                    notificationFeedbackGenerator.notificationOccurred(.error)
                                }
                            }   // end Task
                        },
                        UIAction(
                            title: L10n.Common.Controls.Actions.copy,
                            image: UIImage(systemName: "doc.on.doc"),
                            attributes: [],
                            state: .off
                        ) { [weak self] _ in
                            guard let self = self else { return }
                            Task {
                                let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
                                
                                do {
                                    impactFeedbackGenerator.impactOccurred()
                                    try await self.context.photoLibraryService.copy(
                                        source: .remote(url: assetURL),
                                        resourceType: resourceType
                                    )
                                    self.context.photoLibraryService.presentSuccessNotification()
                                    notificationFeedbackGenerator.notificationOccurred(.success)
                                } catch {
                                    self.context.photoLibraryService.presentFailureNotification(error: error)
                                    notificationFeedbackGenerator.notificationOccurred(.error)
                                }
                            }   // end Task
                        },
                        UIMenu(
                            title: L10n.Common.Controls.Actions.share,
                            image: UIImage(systemName: "square.and.arrow.up"),
                            identifier: nil,
                            options: [],
                            children: [
                                UIAction(
                                    title: L10n.Common.Controls.Actions.ShareMediaMenu.link,
                                    image: UIImage(systemName: "link"),
                                    attributes: [],
                                    state: .off
                                ) { [weak self] _ in
                                    guard let self = self else { return }
                                    Task {
                                        let applicationActivities: [UIActivity] = [
                                            SafariActivity(sceneCoordinator: self.coordinator)
                                        ]
                                        let activityViewController = UIActivityViewController(
                                            activityItems: [assetURL],
                                            applicationActivities: applicationActivities
                                        )
                                        activityViewController.popoverPresentationController?.sourceView = mediaView
                                        self.present(activityViewController, animated: true, completion: nil)
                                    }   // end Task
                                },
                                UIAction(
                                    title: L10n.Common.Controls.Actions.ShareMediaMenu.media,
                                    image: UIImage(systemName: "photo"),
                                    attributes: [],
                                    state: .off
                                ) { [weak self] _ in
                                    guard let self = self else { return }
                                    Task {
                                        let applicationActivities: [UIActivity] = [
                                            SafariActivity(sceneCoordinator: self.coordinator)
                                        ]
                                        // FIXME: handle error
                                        guard let assetData = try await self.context.photoLibraryService.data(from: .remote(url: assetURL)) else {
                                            return
                                        }
                                        let activityViewController = UIActivityViewController(
                                            activityItems: [MediaActivityItemSource(assetURL: assetURL, assetData: assetData)],
                                            applicationActivities: applicationActivities
                                        )
                                        activityViewController.popoverPresentationController?.sourceView = mediaView
                                        self.present(activityViewController, animated: true, completion: nil)
                                    }   // end Task
                                },

                            ]
                        ),
                    ]   // end children
                )   // end return UIMenu
            }
            configuration.indexPath = indexPath
            configuration.index = i
            return configuration
        }   // end for … in …
                
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
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return nil }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return nil }
        if let cell = tableView.cellForRow(at: indexPath) as? StatusViewContainerTableViewCell {
            let mediaViews = cell.statusView.mediaGridContainerView.mediaViews
            guard index < mediaViews.count else { return nil }
            let mediaView = mediaViews[index]
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(roundedRect: mediaView.bounds, cornerRadius: MediaView.cornerRadius)
            return UITargetedPreview(view: mediaView, parameters: parameters)
        } else {
            return nil
        }
    }
        
    func aspectTableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? StatusViewContainerTableViewCell else { return }
        let mediaViews = cell.statusView.mediaGridContainerView.mediaViews
        guard index < mediaViews.count else { return }
        let mediaView = mediaViews[index]
        
        animator.addCompletion {
            Task { [weak self] in
                guard let self = self else { return }
                let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
                guard let item = await self.item(from: source) else {
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
                        containerView: .mediaGridContainerView(cell.statusView.mediaGridContainerView),
                        mediaView: mediaView,
                        index: index
                    )
                )
            }
        }
    }   // end func
    
}
