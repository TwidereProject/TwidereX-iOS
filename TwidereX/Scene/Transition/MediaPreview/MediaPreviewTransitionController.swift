//
//  MediaPreviewTransitionController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class MediaPreviewTransitionController: NSObject {
    
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
        guard let mediaHostViewController = presented as? MediaPreviewViewController else {
            assertionFailure()
            return nil
        }
        
        let transitionItem = MediaPreviewTransitionItem(id: UUID().uuidString, initialFrame: .zero)
        return MediaHostToMediaPreviewViewControllerAnimatedTransitioning(
            operation: .push,
            transitionItem: transitionItem,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard wantsInteractive else {
            return nil
        }

        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        fatalError()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        fatalError()
    }
    
}
