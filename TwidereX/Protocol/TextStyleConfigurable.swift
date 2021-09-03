//
//  TextStyleConfigurable.swift
//  TextStyleConfigurable
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Meta
import MetaTextKit

protocol TextStyleConfigurable {
    func setupLayout(style: TextStyle)
    func setupAttributes(style: TextStyle)
}

enum TextStyle {
    case statusHeader
    case statusAuthorName
    case statusAuthorUsername
    case statusTimestamp
    case statusLocation
    case statusContent
}

extension TextStyle {
    var numberOfLines: Int {
        switch self {
        case .statusHeader:             return 1
        case .statusAuthorName:         return 1
        case .statusAuthorUsername:     return 1
        case .statusTimestamp:          return 1
        case .statusLocation:           return 1
        case .statusContent:            return 0
        }
    }
}

extension TextStyle {
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
        case .statusLocation:
            return .preferredFont(forTextStyle: .caption1)
        case .statusContent:
            return .preferredFont(forTextStyle: .body)
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
        case .statusLocation:
            return .secondaryLabel
        case .statusContent:
            return .label
        }
    }
}

extension MetaLabel: TextStyleConfigurable {
    convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: TextStyle) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: TextStyle) {
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

class PlainLabel: UILabel, TextStyleConfigurable {
    convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: TextStyle) {
        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        
        numberOfLines = style.numberOfLines
    }
    
    func setupAttributes(style: TextStyle) {
        self.font = style.font
        self.textColor = style.textColor
    }
}

extension MetaTextView: TextStyleConfigurable {
    func setupLayout(style: TextStyle) {
        layer.masksToBounds = true
        
        isScrollEnabled = false
    }
    
    func setupAttributes(style: TextStyle) {
        self.font = style.font
        self.textColor = style.textColor
    }
}
