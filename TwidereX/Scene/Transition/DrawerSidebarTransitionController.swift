//
//  DrawerSidebarTransitionController.swift
//  TwidereX
//
//  Created by DTK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

protocol DrawerSidebarTransitionableViewController: UIViewController & NeedsDependency {
    var transitionController: DrawerSidebarTransitionController! { get }
}

final class DrawerSidebarTransitionController: NSObject {

    enum TransitionType {
        case present
        case dismiss
    }
    
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
    
}
