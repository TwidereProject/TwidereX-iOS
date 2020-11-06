//
//  MediaPreviewTransitionController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class MediaPreviewTransitionController: NSObject {
    
    weak var mediaPreviewViewController: MediaPreviewViewController?
    
    var wantsInteractive = false
    private var panGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer()
        gestureRecognizer.maximumNumberOfTouches = 1
        return gestureRecognizer
    }()
    
}

// MARK: - UIViewControllerTransitioningDelegate
extension MediaPreviewTransitionController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let mediaPreviewViewController = presented as? MediaPreviewViewController else {
            assertionFailure()
            return nil
        }
        self.mediaPreviewViewController = mediaPreviewViewController
        
        let transitionItem = MediaPreviewTransitionItem(id: UUID().uuidString)
        return MediaHostToMediaPreviewViewControllerAnimatedTransitioning(
            operation: .push,
            transitionItem: transitionItem,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // not support interactive present
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let mediaPreviewViewController = dismissed as? MediaPreviewViewController else {
            assertionFailure()
            return nil
        }
        let transitionItem = MediaPreviewTransitionItem(id: UUID().uuidString)
        return MediaHostToMediaPreviewViewControllerAnimatedTransitioning(
            operation: .pop,
            transitionItem: transitionItem,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // TODO:
        return nil
    }
    
}
