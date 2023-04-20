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
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        statusViewModel: StatusView.ViewModel,
        mediaViewModel: MediaView.ViewModel,
        previewActionContext: ContextMenuInteractionPreviewActionContext? = nil,
        animated: Bool = true
    ) {
        guard let index = statusViewModel.mediaViewModels.firstIndex(of: mediaViewModel) else {
            assertionFailure("invalid callback")
            return
        }
        let thumbnails = statusViewModel.mediaViewModels.map { $0.thumbnail }

        // note:
        // previewActionContext will automatically dismiss with fade animation style
        previewActionContext?.animator.preferredCommitStyle = .dismiss
        let _initialFrame: CGRect? = {
            guard let platterClippingView = previewActionContext?.platterClippingView() else { return nil }
            return platterClippingView.convert(platterClippingView.frame, to: nil)
        }()
        
        coordinateToMediaPreviewScene(
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
                
                // use the contextMenu previewView frame if possible
                // so that the transition will continue from the previewView position
                item.initialFrame = _initialFrame ?? mediaViewModel.frameInWindow
                
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
            }(),
            animated: animated
        )   // end coordinateToMediaPreviewScene
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        status: StatusRecord,
        mediaPreviewItem: MediaPreviewViewModel.Item,
        mediaPreviewTransitionItem: MediaPreviewTransitionItem,
        animated: Bool
    ) {
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: provider.context,
            authContext: provider.authContext,
            item: mediaPreviewItem,
            transitionItem: mediaPreviewTransitionItem
        )
        provider.coordinator.present(
            scene: .mediaPreview(viewModel: mediaPreviewViewModel),
            from: provider,
            transition: .custom(animated: animated, transitioningDelegate: provider.mediaPreviewTransitionController)
        )
    }

}

extension DataSourceFacade {
    
    @MainActor
    static func responseToMediaViewAction(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        statusViewModel: StatusView.ViewModel,
        mediaViewModel: MediaView.ViewModel,
        action: MediaView.ViewModel.Action
    ) {
        switch action {
        case .preview:
            assert(Thread.isMainThread)
            let status = statusViewModel.status.asRecord
            DataSourceFacade.coordinateToMediaPreviewScene(
                provider: provider,
                status: status,
                statusViewModel: statusViewModel,
                mediaViewModel: mediaViewModel
            )
        case .previewWithContext(let previewActionContext):
            assert(Thread.isMainThread)
            let status = statusViewModel.status.asRecord
            DataSourceFacade.coordinateToMediaPreviewScene(
                provider: provider,
                status: status,
                statusViewModel: statusViewModel,
                mediaViewModel: mediaViewModel,
                previewActionContext: previewActionContext
            )
        case .save:
            Task {
                await responseToMediaViewSaveAction(
                    provider: provider,
                    mediaViewModel: mediaViewModel
                )
            }   // end Task
        case .copy:
            Task {
                await responseToMediaViewCopyAction(
                    provider: provider,
                    mediaViewModel: mediaViewModel
                )
            }   // end Task
        case .shareLink:
            Task {
                await responseToMediaViewShareLinkAction(
                    provider: provider,
                    mediaViewModel: mediaViewModel
                )
            }   // end Task
        case .shareMedia:
            Task {
                await responseToMediaViewShareMediaAction(
                    provider: provider,
                    mediaViewModel: mediaViewModel
                )
            }   // end Task
        }   // end switch
    }
    
}

extension DataSourceFacade {
    
    @MainActor
    static func responseToMediaViewSaveAction(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        mediaViewModel: MediaView.ViewModel
    ) async {
        guard let assetURL = mediaViewModel.downloadURL else { return }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        do {
            impactFeedbackGenerator.impactOccurred()
            try await provider.context.photoLibraryService.save(
                source: .remote(url: assetURL),
                resourceType: mediaViewModel.mediaKind.resourceType
            )
            provider.context.photoLibraryService.presentSuccessNotification(title: L10n.Common.Alerts.PhotoSaved.title)
            notificationFeedbackGenerator.notificationOccurred(.success)
        } catch {
            provider.context.photoLibraryService.presentFailureNotification(
                error: error,
                title: L10n.Common.Alerts.PhotoSaveFail.title,
                message: L10n.Common.Alerts.PhotoSaveFail.message
            )
            notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
    
    @MainActor
    static func responseToMediaViewCopyAction(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        mediaViewModel: MediaView.ViewModel
    ) async {
        guard let assetURL = mediaViewModel.downloadURL else { return }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        do {
            impactFeedbackGenerator.impactOccurred()
            try await provider.context.photoLibraryService.copy(
                source: .remote(url: assetURL),
                resourceType: mediaViewModel.mediaKind.resourceType
            )
            provider.context.photoLibraryService.presentSuccessNotification(title: L10n.Common.Alerts.PhotoCopied.title)
            notificationFeedbackGenerator.notificationOccurred(.success)
        } catch {
            provider.context.photoLibraryService.presentFailureNotification(
                error: error,
                title: L10n.Common.Alerts.PhotoCopied.title,
                message: L10n.Common.Alerts.PhotoCopyFail.message
            )
            notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
    
    @MainActor
    static func responseToMediaViewShareLinkAction(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        mediaViewModel: MediaView.ViewModel
    ) async {
        guard let assetURL = mediaViewModel.downloadURL else { return }
        
        let applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: provider.coordinator)
        ]
        let activityViewController = UIActivityViewController(
            activityItems: [assetURL],
            applicationActivities: applicationActivities
        )
        activityViewController.popoverPresentationController?.sourceRect = mediaViewModel.frameInWindow
        provider.present(activityViewController, animated: true, completion: nil)
    }
    
    @MainActor
    static func responseToMediaViewShareMediaAction(
        provider: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController,
        mediaViewModel: MediaView.ViewModel
    ) async {
        guard let assetURL = mediaViewModel.downloadURL else { return }
        guard let url = try? await provider.context.photoLibraryService.file(from: .remote(url: assetURL)) else {
            return
        }
        
        let applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: provider.coordinator)
        ]
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: applicationActivities
        )
        activityViewController.popoverPresentationController?.sourceRect = mediaViewModel.frameInWindow
        provider.present(activityViewController, animated: true, completion: nil)
    }
}
