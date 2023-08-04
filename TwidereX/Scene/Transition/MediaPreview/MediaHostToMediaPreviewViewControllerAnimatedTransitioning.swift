//
//  MediaHostToMediaPreviewViewControllerAnimatedTransitioning.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import func AVFoundation.AVMakeRect

final class MediaHostToMediaPreviewViewControllerAnimatedTransitioning: ViewControllerAnimatedTransitioning {
    
    let transitionItem: MediaPreviewTransitionItem
    let panGestureRecognizer: UIPanGestureRecognizer

    private var isTransitionContextFinish = false
    
    private var popInteractiveTransitionAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)
    private var itemInteractiveTransitionAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

    init(operation: UINavigationController.Operation, transitionItem: MediaPreviewTransitionItem, panGestureRecognizer: UIPanGestureRecognizer) {
        self.transitionItem = transitionItem
        self.panGestureRecognizer = panGestureRecognizer
        super.init(operation: operation)
    }
    
    class func animator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 4.0, stiffness: 1300, damping: 180, initialVelocity: initialVelocity)
        return UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
    }
    
}

// MARK: - UIViewControllerAnimatedTransitioning
extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)
        
        switch operation {
        case .push:     pushTransition(using: transitionContext).startAnimation()
        case .pop:      popTransition(using: transitionContext).startAnimation()
        default:        return
        }
    }
    
    private func pushTransition(
        using transitionContext: UIViewControllerContextTransitioning,
        curve: UIView.AnimationCurve = .easeInOut
    ) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? MediaPreviewViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }
        
        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = toViewEndFrame
        toView.alpha = 0
        transitionContext.containerView.addSubview(toView)
        // set to image hidden
        toVC.pageViewController.view.alpha = 0
        // set from image hidden. update hidden when paging. seealso: `MediaPreviewViewController`
        transitionItem.source.updateAppearance(position: .start, index: toVC.viewModel.currentPage)
        
        switch transitionItem.source {
        case .none:
            break
        default:
            assert(transitionItem.initialFrame != nil)
        }
        
        // Set transition image view
        let initialFrame = transitionItem.initialFrame ?? toViewEndFrame
        let transitionTargetFrame: CGRect = {
            let aspectRatio = transitionItem.aspectRatio ?? CGSize(width: initialFrame.width, height: initialFrame.height)
            return AVMakeRect(aspectRatio: aspectRatio, insideRect: toView.bounds)
        }()
        let transitionImageView: UIImageView = {
            let imageView = UIImageView(frame: transitionContext.containerView.convert(initialFrame, from: nil))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = false
            imageView.image = transitionItem.image
            // accessibility
            imageView.accessibilityIgnoresInvertColors = true
            return imageView
        }()
        transitionItem.targetFrame = transitionTargetFrame
        transitionItem.transitionView = transitionImageView
        transitionContext.containerView.addSubview(transitionImageView)
        
        toVC.closeButtonBackground.alpha = 0
        
        if UIAccessibility.isReduceTransparencyEnabled {
            toVC.visualEffectView.alpha = 0
        }

        let animator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)
                
        animator.addAnimations {
            transitionImageView.frame = transitionTargetFrame
            toView.alpha = 1
            if UIAccessibility.isReduceTransparencyEnabled {
                toVC.visualEffectView.alpha = 1
            }
        }

        animator.addCompletion { position in
            toVC.pageViewController.view.alpha = 1
            transitionImageView.removeFromSuperview()
            UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
                toVC.closeButtonBackground.alpha = 1
            }
            transitionContext.completeTransition(position == .end)
        }

        return animator
    }
    
    @discardableResult
    private func popTransition(
        using transitionContext: UIViewControllerContextTransitioning,
        curve: UIView.AnimationCurve = .easeInOut
    ) -> UIViewPropertyAnimator {
        let animator = popInteractiveTransitionAnimator
        
        animator.addCompletion { position in
            transitionContext.completeTransition(position == .end)
        }
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MediaPreviewViewController,
              let index = fromVC.pageViewController.currentIndex,
              let fromView = transitionContext.view(forKey: .from),
              let mediaPreviewTransitionViewController = fromVC.pageViewController.currentViewController as? MediaPreviewTransitionViewController,
              let mediaPreviewTransitionContext = mediaPreviewTransitionViewController.mediaPreviewTransitionContext
        else {
            animator.addAnimations {
                self.transitionItem.source.updateAppearance(position: .end, index: nil)
            }
            return animator
        }

        // update close button
        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
            fromVC.closeButtonBackground.alpha = 0
        }
        animator.addCompletion { position in
            UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
                fromVC.closeButtonBackground.alpha = position == .end ? 0 : 1
            }
        }
        
        // update view controller
        fromVC.pageViewController.isUserInteractionEnabled = false
        animator.addCompletion { position in
            fromVC.pageViewController.isUserInteractionEnabled = true
        }
        
        // update background
        let blurEffect = fromVC.visualEffectView.effect
        animator.addAnimations {
            fromVC.visualEffectView.effect = nil
            if UIAccessibility.isReduceTransparencyEnabled {
                fromVC.visualEffectView.alpha = 0
            }
        }
        animator.addCompletion { position in
            fromVC.visualEffectView.effect = position == .end ? nil : blurEffect
            if UIAccessibility.isReduceTransparencyEnabled {
                fromVC.visualEffectView.alpha = position == .end ? 0 : 1
            }
        }
        
        // update mediaInfoDescriptionView
        animator.addAnimations {
            fromVC.mediaInfoDescriptionView.alpha = 0
        }
        
        // update pageControl
        animator.addAnimations {
            fromVC.pageControl.alpha = 0
        }
        
        // update transition item source
        animator.addCompletion { position in
            if position == .end {
                // reset appearance
                self.transitionItem.source.updateAppearance(position: position, index: fromVC.viewModel.currentPage)
            }
        }
        
        // update transitioning snapshot
        let transitionMaskView = UIView(frame: transitionContext.containerView.bounds)
        transitionMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transitionContext.containerView.addSubview(transitionMaskView)
        transitionItem.interactiveTransitionMaskView = transitionMaskView
        
        animator.addCompletion { position in
            transitionMaskView.removeFromSuperview()
        }
        
        let transitionMaskViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        transitionMaskViewTapGestureRecognizer.addTarget(self, action: #selector(MediaHostToMediaPreviewViewControllerAnimatedTransitioning.transitionMaskViewTapGestureRecognizerHandler(_:)))
        transitionMaskView.addGestureRecognizer(transitionMaskViewTapGestureRecognizer)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = transitionMaskView.bounds
        maskLayer.path = UIBezierPath(rect: maskLayer.bounds).cgPath
        transitionMaskView.layer.mask = maskLayer
        transitionItem.interactiveTransitionMaskLayer = maskLayer
    
        // attach transitioning snapshot
        mediaPreviewTransitionContext.snapshot.center = transitionMaskView.center
        mediaPreviewTransitionContext.snapshot.contentMode = .scaleAspectFill
        mediaPreviewTransitionContext.snapshot.clipsToBounds = true
        transitionMaskView.addSubview(mediaPreviewTransitionContext.snapshot)
        fromVC.view.bringSubviewToFront(fromVC.closeButtonBackground)

        transitionItem.transitionView = mediaPreviewTransitionContext.transitionView
        transitionItem.snapshotTransitioning = mediaPreviewTransitionContext.snapshot
        transitionItem.initialFrame = mediaPreviewTransitionContext.snapshot.frame

        // assert view hierarchy not change
        let toVC = transitionItem.previewableViewController
        let targetFrame = toVC.sourceFrame(transitionItem: transitionItem, index: index)
        transitionItem.targetFrame = targetFrame
        
        animator.addAnimations {
            self.transitionItem.snapshotTransitioning?.layer.cornerRadius = self.transitionItem.sourceImageViewCornerRadius ?? 0
        }
        animator.addCompletion { position in
            self.transitionItem.snapshotTransitioning?.layer.cornerRadius = position == .end ? 0 : (self.transitionItem.sourceImageViewCornerRadius ?? 0)
        }
        
        if !isInteractive {
            animator.addAnimations {
                if let targetFrame = targetFrame {
                    self.transitionItem.snapshotTransitioning?.frame = targetFrame
                } else {
                    fromView.alpha = 0
                }
            }
            
            // calculate transition mask
            if let path = createTransitionItemMaskLayerPath(transitionContext: transitionContext) {
                transitionItem.interactiveTransitionMaskLayer?.path = path
            }
        }
        
        mediaPreviewTransitionContext.transitionView.isHidden = true
        animator.addCompletion { position in
            self.transitionItem.transitionView?.isHidden = position == .end
            self.transitionItem.snapshotRaw?.alpha = position == .start ? 1.0 : 0.0
            self.transitionItem.snapshotTransitioning?.removeFromSuperview()
        }
        
        return animator
    }
    
}

// MARK: - UIViewControllerInteractiveTransitioning
extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
     
        switch operation {
        case .pop:
            // Note: change item.imageView transform via pan gesture
            panGestureRecognizer.addTarget(self, action: #selector(MediaHostToMediaPreviewViewControllerAnimatedTransitioning.updatePanGestureInteractive(_:)))
            popInteractiveTransition(using: transitionContext)
        default:
            assertionFailure()
            return
        }
    }
    
    private func popInteractiveTransition(using transitionContext: UIViewControllerContextTransitioning) {
        popTransition(using: transitionContext)
    }
    
}

extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    // app may freeze without response during transitioning
    // patch it by tap the view to finish transitioning
    @objc func transitionMaskViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        // not panning now but still in transitioning
        guard panGestureRecognizer.state == .possible,
              transitionContext.isAnimated, transitionContext.isInteractive else {
            return
        }

        // finish or cancel current transitioning
        let targetPosition = completionPosition()
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: target position: %s", ((#file as NSString).lastPathComponent), #line, #function, targetPosition == .end ? "end" : "start")
        isTransitionContextFinish = true
        animate(targetPosition)

        targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
    }
    
    @objc func updatePanGestureInteractive(_ sender: UIPanGestureRecognizer) {
        guard !isTransitionContextFinish else { return }    // do not accept transition abort

        switch sender.state {
        case .possible:
            return
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let percent = popInteractiveTransitionAnimator.fractionComplete + progressStep(for: translation)
            popInteractiveTransitionAnimator.fractionComplete = percent
            transitionContext.updateInteractiveTransition(percent)
            updateTransitionItemPosition(of: translation)
            
            // Reset translation to zero
            sender.setTranslation(CGPoint.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            let targetPosition = completionPosition()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: target position: %s", ((#file as NSString).lastPathComponent), #line, #function, targetPosition == .end ? "end" : "start")
            isTransitionContextFinish = true
            animate(targetPosition)

            targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
        case .failed:
            return
        @unknown default:
            assertionFailure()
            return
        }
    }

    private func convert(_ velocity: CGPoint, for item: MediaPreviewTransitionItem?) -> CGVector {
        guard let currentFrame = item?.transitionView?.frame, let targetFrame = item?.targetFrame else {
            return CGVector.zero
        }

        let dx = abs(targetFrame.midX - currentFrame.midX)
        let dy = abs(targetFrame.midY - currentFrame.midY)

        guard dx > 0.0 && dy > 0.0 else {
            return CGVector.zero
        }

        let range = CGFloat(35.0)
        let clippedVx = clip(-range, range, velocity.x / dx)
        let clippedVy = clip(-range, range, velocity.y / dy)
        return CGVector(dx: clippedVx, dy: clippedVy)
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        let completionThreshold: CGFloat = 0.33
        let flickMagnitude: CGFloat = 1200 // pts/sec
        let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
        let isFlick = (velocity.magnitude > flickMagnitude)
        let isFlickDown = isFlick && (velocity.dy > 0.0)
        let isFlickUp = isFlick && (velocity.dy < 0.0)

        if (operation == .push && isFlickUp) || (operation == .pop && isFlickDown) {
            return .end
        } else if (operation == .push && isFlickDown) || (operation == .pop && isFlickUp) {
            return .start
        } else if popInteractiveTransitionAnimator.fractionComplete > completionThreshold {
            return .end
        } else {
            return .start
        }
    }

    // Create item animator and start it
    func animate(_ toPosition: UIViewAnimatingPosition) {
        // Create a property animator to animate each image's frame change
        let gestureVelocity = panGestureRecognizer.velocity(in: transitionContext.containerView)
        let velocity = convert(gestureVelocity, for: transitionItem)
        let itemAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: velocity)
        
        // create the mask path and apply it in the to .end animation
        let maskLayerPath: CGPath? = {
            guard toPosition == .end else { return nil }
            let path = createTransitionItemMaskLayerPath(transitionContext: transitionContext)
            return path
        }()

        itemAnimator.addAnimations {
            if let path = maskLayerPath {
                self.transitionItem.interactiveTransitionMaskLayer?.path = path
            }
            if toPosition == .end {
                switch self.transitionItem.source {
                case .profileBanner where toPosition == .end:
                    // fade transition for banner
                    self.transitionItem.snapshotTransitioning?.alpha = 0
                default:
                    if let targetFrame = self.transitionItem.targetFrame {
                        self.transitionItem.snapshotTransitioning?.frame = targetFrame
                    } else {
                        self.transitionItem.snapshotTransitioning?.alpha = 0
                    }
                }
                
            } else {
                if let initialFrame = self.transitionItem.initialFrame {
                    self.transitionItem.snapshotTransitioning?.frame = initialFrame
                } else {
                    self.transitionItem.snapshotTransitioning?.alpha = 1
                }
            }
        }

        // Start the property animator and keep track of it
        self.itemInteractiveTransitionAnimator = itemAnimator
        itemAnimator.startAnimation()

        // Reverse the transition animator if we are returning to the start position
        popInteractiveTransitionAnimator.isReversed = (toPosition == .start)

        if popInteractiveTransitionAnimator.state == .inactive {
            popInteractiveTransitionAnimator.startAnimation()
        } else {
            let durationFactor = CGFloat(itemAnimator.duration / popInteractiveTransitionAnimator.duration)
            popInteractiveTransitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }

    private func progressStep(for translation: CGPoint) -> CGFloat {
        return (operation == .push ? -1.0 : 1.0) * translation.y / transitionContext.containerView.bounds.midY
    }

    private func updateTransitionItemPosition(of translation: CGPoint) {
        let progress = progressStep(for: translation)

        let initialSize = transitionItem.initialFrame!.size
        assert(initialSize != .zero)

        guard let snapshot = transitionItem.snapshotTransitioning,
        let finalSize = transitionItem.targetFrame?.size else {
            return
        }

        if snapshot.frame.size == .zero {
            snapshot.frame.size = initialSize
        }

        let currentSize = snapshot.frame.size

        let itemPercentComplete = clip(-0.05, 1.05, (currentSize.width - initialSize.width) / (finalSize.width - initialSize.width) + progress)
        let itemWidth = lerp(initialSize.width, finalSize.width, itemPercentComplete)
        let itemHeight = lerp(initialSize.height, finalSize.height, itemPercentComplete)
        assert(currentSize.width != 0.0)
        assert(currentSize.height != 0.0)
        let scaleTransform = CGAffineTransform(scaleX: (itemWidth / currentSize.width), y: (itemHeight / currentSize.height))
        let scaledOffset = transitionItem.touchOffset.apply(transform: scaleTransform)

        snapshot.center = (snapshot.center + (translation + (transitionItem.touchOffset - scaledOffset))).point
        snapshot.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: itemWidth, height: itemHeight))
        transitionItem.touchOffset = scaledOffset
    }
    
}

extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    private func createTransitionItemMaskLayerPath(transitionContext: UIViewControllerContextTransitioning) -> CGPath? {
        guard let interactiveTransitionMaskView = transitionItem.interactiveTransitionMaskView else { return nil }
        guard let snapshotTransitioning = transitionItem.snapshotTransitioning else { return nil }
        
        switch transitionItem.source {
        case .mediaView:        break
        case .profileAvatar:    return nil
        case .profileBanner:    return nil
        case .none:             return nil
        }
        
        // cutoff top navigation bar
        let navigationBarCutoffMaskRect: CGRect? = {
            let toVC = transitionItem.previewableViewController
            guard let navigationBar = toVC.navigationController?.navigationBar,
                  let navigationBarSuperView = navigationBar.superview
            else { return nil }
            let navigationBarFrameInWindow = navigationBarSuperView.convert(navigationBar.frame, to: nil)

            var rect = interactiveTransitionMaskView.frame
            let _toViewFrameInWindow = toVC.view.superview.flatMap { $0.convert(toVC.view.frame, to: nil) }
            if let toViewFrameInWindow = _toViewFrameInWindow, toViewFrameInWindow.minY > navigationBarFrameInWindow.maxY {
                rect.origin.y = toViewFrameInWindow.minY
            } else {
                rect.origin.y = navigationBarFrameInWindow.maxY + UIView.separatorLineHeight(of: toVC.view)     // extra hairline
            }
            
            guard snapshotTransitioning.frame.minY > rect.minY else {
                return nil
            }
            return rect
        }()
        
        // cutoff tabBar when bar visible
        let tabBarCutoffMaskRect: CGRect? = {
            let toVC = transitionItem.previewableViewController
            guard let tabBarController = toVC.tabBarController,
                  !tabBarController.tabBar.isHidden,
                  let tabBarSuperView = tabBarController.tabBar.superview
            else { return nil }
            let tabBarFrameInWindow = tabBarSuperView.convert(tabBarController.tabBar.frame, to: nil)

            var rect = interactiveTransitionMaskView.frame
            let offset = rect.maxY - tabBarFrameInWindow.minY
            guard offset > 0 else { return nil }
            rect.size.height -= offset
            return rect
        }()

        var rect = interactiveTransitionMaskView.frame
        let cutoffRects: [CGRect] = [
            navigationBarCutoffMaskRect ?? interactiveTransitionMaskView.frame,
            tabBarCutoffMaskRect ?? interactiveTransitionMaskView.frame
        ]
        for cutoffRect in cutoffRects {
            rect = rect.intersection(cutoffRect)
        }
        
        return UIBezierPath(rect: rect).cgPath
    }
}
