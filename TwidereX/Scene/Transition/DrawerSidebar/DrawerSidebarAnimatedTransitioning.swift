//
//  DrawerSidebarAnimatedTransitioning.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CommonOSLog

final class DrawerSidebarAnimatedTransitioning: ViewControllerAnimatedTransitioning {

    private var animator: UIViewPropertyAnimator?
    private var presentPanDidBegan = false
    
    let screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer
    let panGestureRecognizer: UIPanGestureRecognizer
    
    
    init(
        operation: UINavigationController.Operation,
        screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer,
        panGestureRecognizer: UIPanGestureRecognizer
    ) {
        self.screenEdgePanGestureRecognizer = screenEdgePanGestureRecognizer
        self.panGestureRecognizer = panGestureRecognizer
        super.init(operation: operation)
        
        screenEdgePanGestureRecognizer.addTarget(self, action: #selector(DrawerSidebarAnimatedTransitioning.presentPan(_:)))
        panGestureRecognizer.addTarget(self, action: #selector(DrawerSidebarAnimatedTransitioning.dismisslPan(_:)))
    }
    
    deinit {
        screenEdgePanGestureRecognizer.removeTarget(self, action: nil)
        panGestureRecognizer.removeTarget(self, action: nil)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - UIViewControllerAnimatedTransitioning
extension DrawerSidebarAnimatedTransitioning {
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)
        
        switch operation {
        case .push:     animator = pushTransition(using: transitionContext)
        case .pop:      animator = popTransition(using: transitionContext)
        default:        return
        }
        
        animator?.startAnimation()
    }
    
    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning, timingParameters: UITimingCurveProvider = UISpringTimingParameters()) -> UIViewPropertyAnimator {
        guard let _ = transitionContext.viewController(forKey: .to) as? DrawerSidebarViewController,
              let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            fatalError()
        }

        let transform: CGAffineTransform = {
            let width = transitionContext.containerView.frame.width
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:  return CGAffineTransform(translationX: width, y: 0)
            default:            return CGAffineTransform(translationX: -width, y: 0)
            }
        }()
        transitionContext.containerView.addSubview(toView)
        toView.transform = transform
        fromView.transform = .identity
    
        let separatorLine = SeparatorLineView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        transitionContext.containerView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: toView.topAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: toView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: toView.bottomAnchor),
            separatorLine.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: transitionContext.containerView)),
        ])
        separatorLine.transform = transform
        separatorLine.isUserInteractionEnabled = false
                
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), timingParameters: timingParameters)
        
        animator.addAnimations {
            toView.transform = .identity
            separatorLine.transform = .identity
            fromView.transform = transform.inverted()
        }
        
        animator.addCompletion { position in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: animator completion: %s", ((#file as NSString).lastPathComponent), #line, #function, position.debugDescription)
            
            separatorLine.removeFromSuperview()
            if transitionContext.transitionWasCancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        return animator
    }
    
    private func popTransition(using transitionContext: UIViewControllerContextTransitioning, timingParameters: UITimingCurveProvider = UISpringTimingParameters()) -> UIViewPropertyAnimator {
        guard let _ = transitionContext.viewController(forKey: .from) as? DrawerSidebarViewController,
              let fromView = transitionContext.view(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }

        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.bringSubviewToFront(fromView)
        
        let transform: CGAffineTransform = {
            let width = transitionContext.containerView.frame.width
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:
                return CGAffineTransform(translationX: width, y: 0)
            default:
                return CGAffineTransform(translationX: -width, y: 0)
            }
        }()
        fromView.transform = .identity
        toView.frame.size = transitionContext.finalFrame(for: toViewController).size
        toView.transform = transform.inverted()
        
        let separatorLine = SeparatorLineView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        transitionContext.containerView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: fromView.topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: fromView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: fromView.bottomAnchor),
            separatorLine.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: transitionContext.containerView)),
        ])
        separatorLine.isUserInteractionEnabled = false
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), timingParameters: timingParameters)
        
        animator.addAnimations {
            fromView.transform = transform
            separatorLine.transform = transform
            toView.transform = .identity
        }
        
        animator.addCompletion { position in
            separatorLine.removeFromSuperview()
            if transitionContext.transitionWasCancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        return animator
    }
    
}


// MARK: - UIViewControllerInteractiveTransitioning
extension DrawerSidebarAnimatedTransitioning {
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: operation: %s", ((#file as NSString).lastPathComponent), #line, #function, operation.debugDescription)
        
        switch operation {
        case .push:
            animator = pushTransition(using: transitionContext)
            // fix setup transition success but no following interactive cause stuck issue
            // cancel transition when presentPan not trigger in 0.3s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                guard !self.presentPanDidBegan else {
                    return
                }
                
                self.transitionContext.cancelInteractiveTransition()
                self.animator?.isReversed = true
                self.animator?.startAnimation()
            }
        case .pop:
            animator = popTransition(using: transitionContext)
        default:
            assertionFailure()
            return
        }

    }
    
    @objc private func presentPan(_ sender: UIPanGestureRecognizer) {
        guard let animator = animator else { return }
        presentPanDidBegan = true

        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let width = transitionContext.view(forKey: .to)?.bounds.width ?? transitionContext.containerView.bounds.width
            let direction: CGFloat = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1.0 : -1.0
            let fractionComplete = animator.fractionComplete + (operation == .push ? 1.0 : -1.0) * direction * translation.x / width
            animator.fractionComplete = fractionComplete
            
            transitionContext.updateInteractiveTransition(fractionComplete)
            sender.setTranslation(.zero, in: transitionContext.containerView)
            
        case .ended, .cancelled:
            let position = completionPosition(for: animator, panGestureRecognizer: sender)
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: position: %s", ((#file as NSString).lastPathComponent), #line, #function, position.debugDescription)

            position == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
            
            animator.isReversed = position == .start
            animator.startAnimation()
            
        default:
            assertionFailure()
            return
        }
    }
    
    @objc private func dismisslPan(_ sender: UIPanGestureRecognizer) {
        guard let animator = animator else { return }
        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let width = transitionContext.view(forKey: .from)?.bounds.width ?? transitionContext.containerView.bounds.width
            let direction: CGFloat = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1.0 : -1.0
            let percent = animator.fractionComplete + (operation == .push ? 1.0 : -1.0) * direction * translation.x / width
            animator.fractionComplete = percent
            
            transitionContext.updateInteractiveTransition(percent)
            sender.setTranslation(.zero, in: transitionContext.containerView)
            
        case .ended, .cancelled:
            let position = completionPosition(for: animator, panGestureRecognizer: sender)
            position == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
            
            animator.isReversed = position == .start
            animator.startAnimation()
            
        default:
            return
        }
    }
    
    private func completionPosition(for animator: UIViewPropertyAnimator, panGestureRecognizer: UIPanGestureRecognizer) -> UIViewAnimatingPosition {
        let completionThreshold: CGFloat = 0.33
        let flickMagnitude: CGFloat = 1200 // pts/sec
        let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
        let direction: CGFloat = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1.0 : -1.0
        let isFlick = (velocity.magnitude * direction > flickMagnitude)
        let isFlickRight = isFlick && (velocity.dx > 0.0)
        let isFlickLeft = isFlick && (velocity.dx < 0.0)
        
        if (operation == .push && isFlickRight) || (operation == .pop && isFlickLeft) {
            return .end
        } else if (operation == .push && isFlickLeft) || (operation == .pop && isFlickRight) {
            return .start
        } else if animator.fractionComplete > completionThreshold {
            return .end
        } else {
            return .start
        }
    }
    
}
