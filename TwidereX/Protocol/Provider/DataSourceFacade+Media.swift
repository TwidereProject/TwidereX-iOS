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
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
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
        
        Task {
            await recordStatusHistory(
                denpendency: provider,
                status: status
            )
        }   // end Task
    }
    
}

extension DataSourceFacade {
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        mediaPreviewContext: MediaPreviewContext
    ) async {
        let attachments: [AttachmentObject] = await provider.context.managedObjectContext.perform {
            guard let status = status.object(in: provider.context.managedObjectContext) else { return [] }
            return status.attachments
        }
        let thumbnails = await mediaPreviewContext.thumbnails()
        
        // use standard video player
        if let first = attachments.first, first.kind == .video || first.kind == .audio {
            Task { @MainActor [weak provider] in
                guard let provider = provider else { return }
                // workaround Twitter Video assertURL missing from V2 API issue
                var assetURL: URL
                if let url = first.assetURL {
                    assetURL = url
                } else if case let .twitter(record) = status {
                    let _statusID: String? = await provider.context.managedObjectContext.perform {
                        let status = record.object(in: provider.context.managedObjectContext)
                        return status?.id
                    }
                    guard let statusID = _statusID,
                          case let .twitter(authenticationContext) = provider.context.authenticationService.activeAuthenticationContext
                    else { return }
                    
                    let _response = try? await provider.context.apiService.twitterStatusV1(statusIDs: [statusID], authenticationContext: authenticationContext)
                    guard let status = _response?.value.first,
                          let url = status.extendedEntities?.media?.first?.assetURL.flatMap({ URL(string: $0) })
                    else { return }
                    assetURL = url
                } else {
                    assertionFailure()
                    return
                }
                let playerViewController = AVPlayerViewController()
                playerViewController.player = AVPlayer(url: assetURL)
                playerViewController.player?.play()
                playerViewController.delegate = provider.context.playerService
                provider.present(playerViewController, animated: true, completion: nil)
            }   // end Task
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
            mediaPreviewTransitionItem: {
                // FIXME: allow other source
                let item = MediaPreviewTransitionItem(
                    source: source,
                    previewableViewController: provider
                )
                let mediaView = mediaPreviewContext.mediaView
                
                item.initialFrame = {
                    let initialFrame = mediaView.superview!.convert(mediaView.frame, to: nil)
                    assert(initialFrame != .zero)
                    return initialFrame
                }()
                
                let thumbnail = mediaView.thumbnail()
                item.image = thumbnail
                
                item.aspectRatio = {
                    if let thumbnail = thumbnail {
                        return thumbnail.size
                    }
                    let index = mediaPreviewContext.index
                    guard index < attachments.count else { return nil }
                    let size = attachments[index].size
                    return size
                }()
                
                item.sourceImageViewCornerRadius = MediaView.cornerRadius
                
                return item
            }(),
            mediaPreviewContext: mediaPreviewContext
        )
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        mediaPreviewItem: MediaPreviewViewModel.Item,
        mediaPreviewTransitionItem: MediaPreviewTransitionItem,
        mediaPreviewContext: MediaPreviewContext
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
