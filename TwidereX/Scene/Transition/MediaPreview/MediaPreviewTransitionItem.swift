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
    
    // TODO:
    var imageView: UIImageView?
    var snapshotRaw: UIView?
    var snapshotTransitioning: UIView?
    var initialFrame: CGRect? = nil
    var targetFrame: CGRect? = nil
    var touchOffset: CGVector = CGVector.zero

    init(id: String) {
        self.id = id
    }
    
}
