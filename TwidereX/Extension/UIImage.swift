//
//  UIImage.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-11.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

extension UIImage {
    
    static func placeholder(size: CGSize = CGSize(width: 1, height: 1), color: UIColor) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        
        return render.image { (context: UIGraphicsImageRendererContext) in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
}

