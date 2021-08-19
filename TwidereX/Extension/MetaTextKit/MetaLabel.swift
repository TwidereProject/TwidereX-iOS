//
//  MetaLabel.swift
//  MetaLabel
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextKit

extension MetaLabel {
    enum Style {
        case statusAuthorName
    }
    
    convenience init(style: Style) {
        self.init()
        
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        let font: UIFont
        let textColor: UIColor
        
        switch style {
        case .statusAuthorName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
            textColor = .label
        }
        
        self.font = font
        self.textColor = textColor
        
        textAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
        linkAttributes = [
            .font: font,
            .foregroundColor: ThemeService.shared.theme.value.accentColor
        ]
    }
    
}
