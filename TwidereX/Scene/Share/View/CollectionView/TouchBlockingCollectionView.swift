//
//  TouchBlockingCollectionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TouchBlockingCollectionView: UICollectionView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Blocking responder chain by not call super
        // The subviews in this view will received touch event but superview not
    }
}
