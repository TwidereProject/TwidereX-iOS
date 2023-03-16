//
//  DataSourceFacade+Media.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AVKit
import TwidereCore

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
            return []
//            switch containerView {
//            case .mediaView(let mediaView):
//                let thumbnail = await mediaView.thumbnail()
//                return [thumbnail]
//            case .mediaGridContainerView(let mediaGridContainerView):
//                let thumbnails = await mediaGridContainerView.mediaViews.parallelMap { mediaView in
//                    return await mediaView.thumbnail()
//                }
//                return thumbnails
//            }
        }
    }
    
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        target: StatusTarget,
        status: StatusRecord,
        mediaPreviewContext: MediaPreviewContext
    ) async {
//        let _redirectRecord = await DataSourceFacade.status(
//            managedObjectContext: provider.context.managedObjectContext,
//            status: status,
//            target: target
//        )
//        guard let redirectRecord = _redirectRecord else { return }
//
//        await coordinateToMediaPreviewScene(
//            provider: provider,
//            status: redirectRecord,
//            mediaPreviewContext: mediaPreviewContext
//        )
//
//        Task {
//            await recordStatusHistory(
//                denpendency: provider,
//                status: status
//            )
//        }   // end Task
    }
    
}

extension DataSourceFacade {
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        statusViewModel: StatusView.ViewModel,
        mediaViewModel: MediaView.ViewModel
    ) async {
//        let attachments: [AttachmentObject] = await provider.context.managedObjectContext.perform {
//            guard let status = status.object(in: provider.context.managedObjectContext) else { return [] }
//            return status.attachments
//        }
        guard let index = statusViewModel.mediaViewModels.firstIndex(of: mediaViewModel) else {
            assertionFailure("invalid callback")
            return
        }
        let thumbnails = statusViewModel.mediaViewModels.map { $0.thumbnail }
        
        // use standard video player
//        if let first = attachments.first, first.kind == .video || first.kind == .audio {
//            Task { @MainActor [weak provider] in
//                guard let provider = provider else { return }
//                // workaround Twitter Video assertURL missing from V2 API issue
//                var assetURL: URL
//                if let url = first.assetURL {
//                    assetURL = url
//                } else if case let .twitter(record) = status {
//                    let _statusID: String? = await provider.context.managedObjectContext.perform {
//                        let status = record.object(in: provider.context.managedObjectContext)
//                        return status?.id
//                    }
//                    guard let statusID = _statusID,
//                          case let .twitter(authenticationContext) = provider.authContext.authenticationContext
//                    else { return }
//
//                    let _response = try? await provider.context.apiService.twitterStatusV1(statusIDs: [statusID], authenticationContext: authenticationContext)
//                    guard let status = _response?.value.first,
//                          let url = status.extendedEntities?.media?.first?.assetURL.flatMap({ URL(string: $0) })
//                    else { return }
//                    assetURL = url
//                } else {
//                    assertionFailure()
//                    return
//                }
//                let playerViewController = AVPlayerViewController()
//                playerViewController.player = AVPlayer(url: assetURL)
//                playerViewController.player?.play()
//                playerViewController.delegate = provider.context.playerService
//                provider.present(playerViewController, animated: true, completion: nil)
//            }   // end Task
//            return
//        }
        
        
        await coordinateToMediaPreviewScene(
            provider: provider,
            status: status,
            mediaPreviewItem: .statusMedia(.init(
                status: status,
                mediaViewModels: statusViewModel.mediaViewModels,
                initialIndex: index,
                preloadThumbnails: thumbnails
            )),
            mediaPreviewTransitionItem: {
                let source = MediaPreviewTransitionItem.Source.mediaView(mediaViewModel)
                let item = MediaPreviewTransitionItem(
                    source: source,
                    previewableViewController: provider
                )
                
                item.initialFrame = mediaViewModel.frameInWindow
                
                let thumbnail = mediaViewModel.thumbnail
                item.image = thumbnail
                
                item.aspectRatio = {
                    if let thumbnail = thumbnail {
                        return thumbnail.size
                    }
                    return mediaViewModel.aspectRatio
                }()
                
                item.sourceImageViewCornerRadius = MediaGridContainerView.cornerRadius
                
                return item
            }()
        )   // end coordinateToMediaPreviewScene
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        mediaPreviewItem: MediaPreviewViewModel.Item,
        mediaPreviewTransitionItem: MediaPreviewTransitionItem
    ) async {
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: provider.context,
            authContext: provider.authContext,
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
