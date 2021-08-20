//
//  MetaLabel.swift
//  MetaLabel
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Meta
import MetaTextKit

protocol MetaStyleConfigurable {
    func setupLayout(style: Meta.Style)
    func setupAttributes(style: Meta.Style)
}

extension Meta {
    enum Style {
        case statusAuthorName
        case statusAuthorUsername
    }
}

extension Meta.Style {
    var numberOfLines: Int {
        switch self {
        case .statusAuthorName:         return 1
        case .statusAuthorUsername:     return 1
        }
    }
}

extension Meta.Style {
    var font: UIFont {
        switch self {
        case .statusAuthorName:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
        case .statusAuthorUsername:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .regular))
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .statusAuthorName:
            return .label
        case .statusAuthorUsername:
            return .secondaryLabel
        }
    }
}


extension MetaLabel: MetaStyleConfigurable {
    convenience init(style: Meta.Style) {
        self.init()

        setupLayout(style: style)
        setupAttributes(style: style)
    }

    func setupLayout(style: Meta.Style) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: Meta.Style) {
        let font = style.font
        let textColor = style.textColor

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

class PlainMetaLabel: UILabel, MetaStyleConfigurable {
    convenience init(style: Meta.Style) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: Meta.Style) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: Meta.Style) {
        self.font = style.font
        self.textColor = style.textColor
    }
}
