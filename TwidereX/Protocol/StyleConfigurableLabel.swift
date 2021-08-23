//
//  StyleConfigurableLabel.swift
//  StyleConfigurableLabel
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Meta
import MetaTextKit

protocol StyleConfigurableLabel {
    func setupLayout(style: UILabel.Style)
    func setupAttributes(style: UILabel.Style)
}

extension UILabel {
    enum Style {
        case statusHeader
        case statusAuthorName
        case statusAuthorUsername
        case statusTimestamp
    }
}

extension UILabel.Style {
    var numberOfLines: Int {
        switch self {
        case .statusHeader:             return 1
        case .statusAuthorName:         return 1
        case .statusAuthorUsername:     return 1
        case .statusTimestamp:          return 1
        }
    }
}

extension UILabel.Style {
    var font: UIFont {
        switch self {
        case .statusHeader:
            return .preferredFont(forTextStyle: .footnote)
        case .statusAuthorName:
            return .preferredFont(forTextStyle: .headline)
        case .statusAuthorUsername:
            return .preferredFont(forTextStyle: .subheadline)
        case .statusTimestamp:
            return .preferredFont(forTextStyle: .subheadline)
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .statusHeader:
            return .secondaryLabel
        case .statusAuthorName:
            return .label
        case .statusAuthorUsername:
            return .secondaryLabel
        case .statusTimestamp:
            return .secondaryLabel
        }
    }
}

extension MetaLabel: StyleConfigurableLabel {
    convenience init(style: UILabel.Style) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: UILabel.Style) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: UILabel.Style) {
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

class PlainLabel: UILabel, StyleConfigurableLabel {
    convenience init(style: UILabel.Style) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: UILabel.Style) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: UILabel.Style) {
        self.font = style.font
        self.textColor = style.textColor
    }
}
