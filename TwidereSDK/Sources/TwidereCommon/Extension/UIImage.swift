//
//  UIImage.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import UIKit
import func AVFoundation.AVMakeRect

extension UIImage {
    public func resize(for size: CGSize) -> UIImage {
        let rect = AVMakeRect(
            aspectRatio: self.size,
            insideRect: CGRect(origin: .zero, size: size)
        )
        return UIGraphicsImageRenderer(size: rect.size).image { context in
            self.draw(in: CGRect(origin: .zero, size: rect.size))
        }
    }
}
