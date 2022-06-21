//
//  UIViewController.swift
//  
//
//  Created by MainasuK on 2022-5-27.
//

import UIKit

extension UIViewController {
    
    public static var top: UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            
            let keyWindow = windowScene.windows.filter { $0.isKeyWindow }.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                
                return topController
            }
        }
        
        return nil 
    }
    
}
