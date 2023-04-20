//
//  UIViewController.swift
//  
//
//  Created by MainasuK on 2023/3/17.
//

import UIKit

extension UIViewController {
    
    /// Returns the top most view controller from given view controller's stack.
    public var topMost: UIViewController? {
        // presented view controller
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMost
        }
        
        // UITabBarController
        if let tabBarController = self as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMost
        }
        
        // UINavigationController
        if let navigationController = self as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMost
        }
        
        // UIPageController
        if let pageViewController = self as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return pageViewController.viewControllers?.first?.topMost ?? self
        }
        
        // child view controller
        for subview in self.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return childViewController.topMost
            }
        }
        
        return self
    }
    
}
