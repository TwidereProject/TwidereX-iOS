//
//  MetaTextAreaLayer.swift
//  MetaTextAreaLayer
//
//  Created by Cirno MainasuK on 2021-7-30.
//

import UIKit

class MetaTextAreaLayer: CALayer {
    override class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default animation of opacity when adding comment bubbles.
        return NSNull()
    }
}
