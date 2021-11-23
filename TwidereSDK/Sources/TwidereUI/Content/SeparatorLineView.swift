//
//  SeparatorLineView.swift
//  SeparatorLineView
//
//  Created by Cirno MainasuK on 2021-9-1.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

public final class SeparatorLineView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override var intrinsicContentSize: CGSize {
        let height = 1.0 / traitCollection.displayScale     // 1px
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: height)
    }
    
}

extension SeparatorLineView {
    private func _init() {
        backgroundColor = .separator
    }
}
