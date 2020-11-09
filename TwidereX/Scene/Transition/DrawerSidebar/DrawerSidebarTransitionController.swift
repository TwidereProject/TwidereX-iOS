//
//  DrawerSidebarTransitionController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

protocol DrawerSidebarTransitionableViewController: UIViewController & NeedsDependency {
    var drawerSidebarTransitionController: DrawerSidebarTransitionController! { get }
    var avatarButton: UIButton { get }
}

final class DrawerSidebarTransitionController: NSObject {
    
    weak var drawerSidebarTransitionableViewController: DrawerSidebarTransitionableViewController?
    weak var drawerSidebarViewController: DrawerSidebarViewController?
    
    private var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let gestureRecognizer = UIScreenEdgePanGestureRecognizer()
        gestureRecognizer.maximumNumberOfTouches = 1
        gestureRecognizer.edges = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
        return gestureRecognizer
    }()
    
    private var panGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer()
        gestureRecognizer.maximumNumberOfTouches = 1
        return gestureRecognizer
    }()
    
    private(set) var transitionType: TransitionType?
    private var interactiveTransitioning: UIViewControllerInteractiveTransitioning?
    
    var wantsInteractive = false
    
    init(drawerSidebarTransitionableViewController: DrawerSidebarTransitionableViewController) {
        self.drawerSidebarTransitionableViewController = drawerSidebarTransitionableViewController
        super.init()
        
        drawerSidebarTransitionableViewController.transitioningDelegate = self
        
        // edge pan present gesture
        screenEdgePanGestureRecognizer.delegate = self
        screenEdgePanGestureRecognizer.addTarget(self, action: #selector(DrawerSidebarTransitionController.edgePan(_:)))
        drawerSidebarTransitionableViewController.view.addGestureRecognizer(screenEdgePanGestureRecognizer)
        if let interactivePopGestureRecognizer = drawerSidebarTransitionableViewController.navigationController?.interactivePopGestureRecognizer {
            screenEdgePanGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
        }
        
        // pan dismiss gesture
        panGestureRecognizer.delegate = self
        panGestureRecognizer.addTarget(self, action: #selector(DrawerSidebarTransitionController.pan(_:)))
    }
    
}

extension DrawerSidebarTransitionController {
    enum TransitionType {
        case present
        case dismiss
    }
}


// MARK: - UIViewControllerTransitioningDelegate
extension DrawerSidebarTransitionController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let drawerSidebarViewController = presented as? DrawerSidebarViewController else {
            assertionFailure()
            return nil
        }

        self.drawerSidebarViewController = drawerSidebarViewController
        drawerSidebarViewController.view.addGestureRecognizer(panGestureRecognizer)
        return DrawerSidebarAnimatedTransitioning(
            operation: .push,
            screenEdgePanGestureRecognizer: screenEdgePanGestureRecognizer,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard wantsInteractive else {
            return nil
        }
        
        if let transition = animator as? DrawerSidebarAnimatedTransitioning {
            transition.delegate = self
            interactiveTransitioning = transition
            return transition
        }
        
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DrawerSidebarAnimatedTransitioning(
            operation: .pop,
            screenEdgePanGestureRecognizer: screenEdgePanGestureRecognizer,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard wantsInteractive else {
            return nil
        }
        
        if let transition = animator as? DrawerSidebarAnimatedTransitioning {
            transition.delegate = self
            interactiveTransitioning = transition
            return transition
        }
        
        return nil
    }
    
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        return SidebarPresentationController(presentedViewController: presented, presenting: presenting)
//    }
    
}

extension DrawerSidebarTransitionController {

    @objc private func edgePan(_ sender: UIPanGestureRecognizer) {
        guard let transitionType = transitionType else { return }
        guard sender.state == .began else { return }

        // check transition is not on the fly
        guard interactiveTransitioning == nil else {
            return
        }

        switch transitionType {
        case .present:
            wantsInteractive = true
            drawerSidebarTransitionableViewController?.coordinator.present(
                scene: .drawerSidebar,
                from: drawerSidebarTransitionableViewController,
                transition: .custom(transitioningDelegate: self)
            )

        case .dismiss:
            assertionFailure()
            break
        }
    }
    
    @objc private func pan(_ sender: UIPanGestureRecognizer) {
        guard let transitionType = transitionType else { return }
        guard sender.state == .began else { return }

        // check transition is not on the fly
        guard interactiveTransitioning == nil else {
            return
        }

        switch transitionType {
        case .present:
            assertionFailure()
            break
        case .dismiss:
            wantsInteractive = true
            drawerSidebarViewController?.dismiss(animated: true, completion: nil)
        }
    }

}

// MARK: - UIGestureRecognizerDelegate
extension DrawerSidebarTransitionController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if drawerSidebarTransitionableViewController?.navigationController?.topViewController is DrawerSidebarTransitionableViewController {
            if (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer.view is UITableView) ||
               (otherGestureRecognizer is UIPanGestureRecognizer && gestureRecognizer.view is UITableView) {
                // disable tableView scroll when pan
                return false
            }
        }

        if gestureRecognizer is UIPanGestureRecognizer, otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }

        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // allow non-transitioning gesture recognizer if needs
        guard gestureRecognizer === screenEdgePanGestureRecognizer || gestureRecognizer === panGestureRecognizer else {
            return true
        }
        
        // accept interrupt interactive
        if let _ = interactiveTransitioning as? DrawerSidebarAnimatedTransitioning {
            return wantsInteractive
        }
        
        if gestureRecognizer === screenEdgePanGestureRecognizer, drawerSidebarTransitionableViewController != nil {
            transitionType = .present
            return true
        }
        
        if gestureRecognizer === panGestureRecognizer, drawerSidebarViewController != nil {
            transitionType = .dismiss
            return true
        }
        
        transitionType = nil
        return false
    }
    
}

// MARK: - ViewControllerAnimatedTransitioningDelegate
extension DrawerSidebarTransitionController: ViewControllerAnimatedTransitioningDelegate {
    
    var wantsInteractiveStart: Bool {
        return wantsInteractive
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, transitionCompleted.description)

        interactiveTransitioning = nil
        wantsInteractive = false
        transitionType = nil
    }
    
}
