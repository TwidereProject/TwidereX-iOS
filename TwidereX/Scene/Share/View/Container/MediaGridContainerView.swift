//
//  MediaGridContainerView.swift
//  MediaGridContainerView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class MediaGridContainerView: UIView {
    
    private(set) var mediaViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MediaGridContainerView {
    private func _init() {
        
    }
}
