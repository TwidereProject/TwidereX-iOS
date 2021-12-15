//
//  DataSourceFacade+Media.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AVKit
import TwidereUI

extension DataSourceFacade {
    
    struct MediaPreviewContext {
        // let statusView: StatusView
        let containerView: ContainerView
        let mediaView: MediaView
        let index: Int
        
        enum ContainerView {
            case mediaView(MediaView)
            case mediaGridContainerView(MediaGridContainerView)
        }
        
        func thumbnails() async -> [UIImage?] {
            switch containerView {
            case .mediaView(let mediaView):
                let thumbnail = await mediaView.thumbnail()
                return [thumbnail]
            case .mediaGridContainerView(let mediaGridContainerView):
                let thumbnails = await mediaGridContainerView.mediaViews.parallelMap { mediaView in
                    return await mediaView.thumbnail()
                }
                return thumbnails
            }
        }
    }
    
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & MediaPreviewTransitionHostViewController,
        target: StatusTarget,
        status: StatusRecord,
        mediaPreviewContext: MediaPreviewContext
    ) async {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        await coordinateToMediaPreviewScene(
            provider: provider,
            status: redirectRecord,
            mediaPreviewContext: mediaPreviewContext
        )
    }
    
}

extension DataSourceFacade {
    
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & MediaPreviewTransitionHostViewController,
        status: StatusRecord,
        mediaPreviewContext: MediaPreviewContext
    ) async {
        let attachments: [AttachmentObject] = await provider.context.managedObjectContext.perform {
            guard let status = status.object(in: provider.context.managedObjectContext) else { return [] }
            return status.attachments
        }
        let thumbnails = await mediaPreviewContext.thumbnails()
        
        // FIXME:
        if let first = attachments.first,
           first.kind == .video || first.kind == .audio
        {
            if let assetURL = first.assetURL {
                Task { @MainActor [weak provider] in
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = AVPlayer(url: assetURL)
                    playerViewController.player?.isMuted = true
                    playerViewController.player?.play()
                    provider?.present(playerViewController, animated: true, completion: nil)
                }
            } else {
                // do nothing
            }
            return
        }
        
        let source: MediaPreviewTransitionItem.Source = {
            switch mediaPreviewContext.containerView {
            case .mediaView(let mediaView):
                return .attachment(mediaView)
            case .mediaGridContainerView(let mediaGridContainerView):
                return .attachments(mediaGridContainerView)
            }
        }()
        
        await coordinateToMediaPreviewScene(
            provider: provider,
            status: status,
            mediaPreviewItem: .statusAttachment(.init(
                status: status,
                attachments: attachments,
                initialIndex: mediaPreviewContext.index,
                preloadThumbnails: thumbnails
            )),
            mediaPreviewTransitionItem: MediaPreviewTransitionItem(
                source: source,
                transitionHostViewController: provider
            ),
            mediaPreviewContext: mediaPreviewContext
        )
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & MediaPreviewTransitionHostViewController,
        status: StatusRecord,
        mediaPreviewItem: MediaPreviewViewModel.Item,
        mediaPreviewTransitionItem: MediaPreviewTransitionItem,
        mediaPreviewContext: MediaPreviewContext
    ) async {
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: provider.context,
            item: mediaPreviewItem,
            transitionItem: mediaPreviewTransitionItem
        )
        provider.coordinator.present(
            scene: .mediaPreview(viewModel: mediaPreviewViewModel),
            from: provider,
            transition: .custom(transitioningDelegate: provider.mediaPreviewTransitionController)
        )
    }
    
}
