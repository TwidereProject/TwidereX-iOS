//
//  HitTestExpandedButton.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-6-4.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

final class HitTestExpandedButton: UIButton {
    
    var expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: expandEdgeInsets).contains(point)
    }
    
}
