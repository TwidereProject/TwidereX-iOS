//
//  SeparatorLineView.swift
//  SeparatorLineView
//
//  Created by Cirno MainasuK on 2021-9-1.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class SeparatorLineView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override var intrinsicContentSize: CGSize {
        let height = 1.0 / traitCollection.displayScale     // 1px
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: height)
    }
    
}

extension SeparatorLineView {
    private func _init() {
        backgroundColor = .separator
    }
}
