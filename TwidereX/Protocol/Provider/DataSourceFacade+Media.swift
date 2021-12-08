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
        let statusView: StatusView
        let containerView: MediaGridContainerView
        let mediaView: MediaView
        let index: Int
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
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & MediaPreviewTransitionHostViewController,
        status: StatusRecord,
        mediaPreviewContext: MediaPreviewContext
    ) async {
        let attachments: [AttachmentObject] = await provider.context.managedObjectContext.perform {
            guard let status = status.object(in: provider.context.managedObjectContext) else { return [] }
            return status.attachments
        }
        let thumbnails = await mediaPreviewContext.containerView.mediaViews.parallelMap { mediaView in
            return await mediaView.thumbnail()
        }
        
        // FIXME:
        if let first = attachments.first,
           let assetURL = first.assetURL,
           first.kind == .video || first.kind == .audio
        {
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: assetURL)
            playerViewController.player?.play()
            provider.present(playerViewController, animated: true, completion: nil)
            return
        }
        
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: provider.context,
            item: .statusAttachment(.init(
                status: status,
                attachments: attachments,
                initialIndex: mediaPreviewContext.index,
                preloadThumbnails: thumbnails
            )),
            transitionItem: MediaPreviewTransitionItem(
                source: .attachments(mediaPreviewContext.containerView),
                transitionHostViewController: provider
            )
        )
        provider.coordinator.present(
            scene: .mediaPreview(viewModel: mediaPreviewViewModel),
            from: provider,
            transition: .custom(transitioningDelegate: provider.mediaPreviewTransitionController)
        )
    }
    
}
