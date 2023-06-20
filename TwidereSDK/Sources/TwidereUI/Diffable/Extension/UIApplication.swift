//
//  UIApplication.swift
//  
//
//  Created by MainasuK on 2022-6-20.
//

import UIKit

extension UIApplication {
    public var keyWindowScene: UIWindowScene? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindowScene = windowScenes.first(where: { $0.keyWindow != nil }) {
            return keyWindowScene
        }
        
        return nil
    }
}
