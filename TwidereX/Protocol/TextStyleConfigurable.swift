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
import MetaTextArea

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
    case userAuthorName
    case userAuthorUsername
    case userDescription
    case profileAuthorName
    case profileAuthorUsername
    case profileAuthorBio
    case profileFieldKey
    case profileFieldValue
    case hashtagTitle
    case hashtagDescription
    
    case custom(Configuration)
    struct Configuration {
        let font: UIFont
        let textColor: UIColor
    }
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
        case .userAuthorName:           return 1
        case .userAuthorUsername:       return 1
        case .userDescription:          return 1
        case .profileAuthorName:        return 0
        case .profileAuthorUsername:    return 1
        case .profileAuthorBio:         return 0
        case .profileFieldKey:          return 1
        case .profileFieldValue:        return 0
        case .hashtagTitle:             return 1
        case .hashtagDescription:       return 1
        case .custom:                   return 1
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
        case .userAuthorName:
            return .preferredFont(forTextStyle: .headline)
        case .userAuthorUsername:
            return .preferredFont(forTextStyle: .subheadline)
        case .userDescription:
            return .preferredFont(forTextStyle: .subheadline)
        case .profileAuthorName:
            return .preferredFont(forTextStyle: .headline)
        case .profileAuthorUsername:
            return .preferredFont(forTextStyle: .subheadline)
        case .profileAuthorBio:
            return .preferredFont(forTextStyle: .callout)
        case .profileFieldKey:
            return .preferredFont(forTextStyle: .footnote)
        case .profileFieldValue:
            return .preferredFont(forTextStyle: .footnote)
        case .hashtagTitle:
            return .preferredFont(forTextStyle: .headline)
        case .hashtagDescription:
            return .preferredFont(forTextStyle: .subheadline)
        case .custom(let configuration):
            return configuration.font
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
            return .label.withAlphaComponent(0.8)
        case .userAuthorName:
            return .label
        case .userAuthorUsername:
            return .secondaryLabel
        case .userDescription:
            return .secondaryLabel
        case .profileAuthorName:
            return .label
        case .profileAuthorUsername:
            return .secondaryLabel
        case .profileAuthorBio:
            return .label
        case .profileFieldKey:
            return .secondaryLabel
        case .profileFieldValue:
            return .label
        case .hashtagTitle:
            return .label
        case .hashtagDescription:
            return .secondaryLabel
        case .custom(let configuration):
            return configuration.textColor
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
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        numberOfLines = style.numberOfLines
        
        switch style {
        case .statusHeader:
            break
        case .statusAuthorName:
            break
        case .statusAuthorUsername:
            break
        case .statusTimestamp:
            break
        case .statusLocation:
            break
        case .statusContent:
            break
        case .userAuthorName:
            break
        case .userAuthorUsername:
            break
        case .userDescription:
            break
        case .profileAuthorName, .profileAuthorUsername:
            textAlignment = .center
            paragraphStyle.alignment = .center
        case .profileAuthorBio:
            break
        case .profileFieldKey:
            break
        case .profileFieldValue:
            break
        case .hashtagTitle:
            break
        case .hashtagDescription:
            break
        case .custom:
            break
        }
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
        isScrollEnabled = false
    }
    
    func setupAttributes(style: TextStyle) {
        self.font = style.font
        self.textColor = style.textColor
    }
}

extension MetaTextAreaView: TextStyleConfigurable {
    
    convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    func setupLayout(style: TextStyle) {
        // do nothing
    }
    
    func setupAttributes(style: TextStyle) {
        textAttributes = [
            .font: style.font,
            .foregroundColor: style.textColor
        ]
        linkAttributes = [
            .font: style.font,
            .foregroundColor: Asset.Colors.Theme.daylight.color,
        ]
    }
}
