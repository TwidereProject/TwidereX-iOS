//
//  MediaPreviewTransitionItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

class MediaPreviewTransitionItem: Identifiable {
    
    let id: String
    let initialFrame: CGRect
    
    var targetFrame: CGRect? = nil
    var imageView: UIImageView? = nil
    var touchOffset: CGVector = CGVector.zero

    init(
        id: String,
        initialFrame: CGRect
    ) {
        self.id = id
        self.initialFrame = initialFrame
    }
    
}
