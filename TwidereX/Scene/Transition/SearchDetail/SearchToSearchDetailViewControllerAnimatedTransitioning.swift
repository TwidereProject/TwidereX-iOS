//
//  SearchToSearchDetailViewControllerAnimatedTransitioning.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

final class SearchToSearchDetailViewControllerAnimatedTransitioning: ViewControllerAnimatedTransitioning {
    
    private var animator: UIViewPropertyAnimator?
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - UIViewControllerAnimatedTransitioning
extension SearchToSearchDetailViewControllerAnimatedTransitioning {
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)
        
        switch operation {
        case .push:     pushTransition(using: transitionContext).startAnimation()
        case .pop:      popTransition(using: transitionContext).startAnimation()
        default:        return
        }
    }
    
    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeInOut) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? SearchDetailViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }
        
        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        transitionContext.containerView.addSubview(toView)
        toView.frame = toViewEndFrame

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: curve)
        animator.addAnimations {
            
        }
        animator.addCompletion { position in
            transitionContext.completeTransition(true)
        }
        return animator
    }
    
    private func popTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeInOut) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? SearchViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }
        
        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        transitionContext.containerView.addSubview(toView)
        toView.frame = toViewEndFrame
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: curve)
        animator.addAnimations {
            
        }
        animator.addCompletion { position in
            transitionContext.completeTransition(true)
        }
        return animator
    }
}
