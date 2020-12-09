//
//  UITapGestureRecognizer.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UITapGestureRecognizer {
    
    static var singleTapGestureRecognizer: UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }
    
    static var doubleTapGestureRecognizer: UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 2
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }
    
}
