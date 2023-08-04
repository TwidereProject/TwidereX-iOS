//
//  MediaPreviewableViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

protocol MediaPreviewableViewController: UIViewController {
    var mediaPreviewTransitionController: MediaPreviewTransitionController { get }
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect?
}

extension MediaPreviewableViewController {
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect? {
        switch transitionItem.source {
        case .none:
            guard let view = mediaPreviewTransitionController.mediaPreviewViewController?.view else { return nil }
            let frame = CGRect(
                x: view.frame.midX,
                y: 1.5 * view.frame.maxY,
                width: 44,
                height: 44
            )
            return frame
        case .mediaView(let mediaViewModel, let viewModels):
            guard let _viewModel = viewModels[safe: index] else {
                guard mediaViewModel.frameInWindow != .zero else { return nil }
                return mediaViewModel.frameInWindow
            }
            guard _viewModel.frameInWindow != .zero else { return nil }
            return _viewModel.frameInWindow
        case .profileAvatar:
            return nil      // TODO:
        case .profileBanner:
            return nil      // TODO:
        }
    }
}
