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
import MetaLabel
import MetaTextArea
import TwidereAsset

public protocol TextStyleConfigurable {
    func setupLayout(style: TextStyle)
    func setupAttributes(style: TextStyle)
}

public enum TextStyle {
    case statusHeader
    case statusAuthorName
    case statusAuthorUsername
    case statusTimestamp
    case statusLocation
    case statusContent
    case statusMetrics
    case userAuthorName
    case pollOptionTitle
    case pollOptionPercentage
    case pollVoteDescription
    case userAuthorUsername
    case userDescription
    case profileAuthorName
    case profileAuthorUsername
    case profileAuthorBio
    case profileFieldKey
    case profileFieldValue
    case mediaDescriptionAuthorName
    case hashtagTitle
    case hashtagDescription
    case listPrimaryText
    case searchHistoryTitle
    case searchTrendTitle
    case searchTrendSubtitle
    case searchTrendCount
    case sidebarAuthorName
    case sidebarAuthorUsername
    
    case custom(Configuration)
    public struct Configuration {
        public let font: UIFont
        public let textColor: UIColor
        
        public init(
            font: UIFont,
            textColor: UIColor
        ) {
            self.font = font
            self.textColor = textColor
        }
    }
}

extension TextStyle {
    public var numberOfLines: Int {
        switch self {
        case .statusHeader:                 return 1
        case .statusAuthorName:             return 1
        case .statusAuthorUsername:         return 1
        case .statusTimestamp:              return 1
        case .statusLocation:               return 1
        case .statusContent:                return 0
        case .statusMetrics:                return 1
        case .pollOptionTitle:              return 1
        case .pollOptionPercentage:         return 1
        case .pollVoteDescription:          return 1
        case .userAuthorName:               return 1
        case .userAuthorUsername:           return 1
        case .userDescription:              return 1
        case .profileAuthorName:            return 0
        case .profileAuthorUsername:        return 1
        case .profileAuthorBio:             return 0
        case .profileFieldKey:              return 1
        case .profileFieldValue:            return 0
        case .mediaDescriptionAuthorName:   return 1
        case .hashtagTitle:                 return 1
        case .hashtagDescription:           return 1
        case .listPrimaryText:              return 1
        case .searchHistoryTitle:           return 1
        case .searchTrendTitle:             return 1
        case .searchTrendSubtitle:          return 1
        case .searchTrendCount:             return 1
        case .sidebarAuthorName:            return 1
        case .sidebarAuthorUsername:        return 1
        case .custom:                       return 1
        }
    }
}

extension TextStyle {
    public var font: UIFont {
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
        case .statusMetrics:
            return .preferredFont(forTextStyle: .footnote)
        case .pollOptionTitle:
            return .systemFont(ofSize: 15, weight: .regular)
        case .pollOptionPercentage:
            return .systemFont(ofSize: 12, weight: .regular)
        case .pollVoteDescription:
            return .systemFont(ofSize: 14, weight: .regular)
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
        case .mediaDescriptionAuthorName:
            return .preferredFont(forTextStyle: .headline)
        case .hashtagTitle:
            return .preferredFont(forTextStyle: .headline)
        case .hashtagDescription:
            return .preferredFont(forTextStyle: .subheadline)
        case .listPrimaryText:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: .preferredFont(forTextStyle: .body))
        case .searchHistoryTitle:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: .preferredFont(forTextStyle: .body))
        case .searchTrendTitle:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: .preferredFont(forTextStyle: .body))
        case .searchTrendSubtitle:
            return .preferredFont(forTextStyle: .subheadline)
        case .searchTrendCount:
            return .preferredFont(forTextStyle: .footnote)
        case .sidebarAuthorName:
            return .systemFont(ofSize: 16, weight: .regular)
        case .sidebarAuthorUsername:
            return .systemFont(ofSize: 14, weight: .regular)
        case .custom(let configuration):
            return configuration.font
        }
    }
    
    public var textColor: UIColor {
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
        case .statusMetrics:
            return .secondaryLabel
        case .userAuthorName:
            return .label
        case .pollOptionTitle:
            return .secondaryLabel
        case .pollOptionPercentage:
            return .secondaryLabel
        case .pollVoteDescription:
            return .secondaryLabel
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
        case .mediaDescriptionAuthorName:
            // force white due to media view controller override to dark mode
            return .white
        case .hashtagTitle:
            return .label
        case .hashtagDescription:
            return .secondaryLabel
        case .listPrimaryText:
            return .label
        case .searchHistoryTitle:
            return .label
        case .searchTrendTitle:
            return .label
        case .searchTrendSubtitle:
            return .secondaryLabel
        case .sidebarAuthorName:
            return .label
        case .searchTrendCount:
            return .secondaryLabel
        case .sidebarAuthorUsername:
            return .secondaryLabel
        case .custom(let configuration):
            return configuration.textColor
        }
    }
}

extension MetaLabel: TextStyleConfigurable {
    public convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    public func setupLayout(style: TextStyle) {
        // do nothing due to cannot tweak TextKit 2
    }
    
    public func setupAttributes(style: TextStyle) {
        let font = style.font
        let textColor = style.textColor
        
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

public class PlainLabel: UILabel, TextStyleConfigurable {
    public convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    public func setupLayout(style: TextStyle) {
        lineBreakMode = .byTruncatingTail
        
        numberOfLines = style.numberOfLines
    }
    
    public func setupAttributes(style: TextStyle) {
        self.font = style.font
        self.textColor = style.textColor
    }
}

extension MetaTextView: TextStyleConfigurable {
    public func setupLayout(style: TextStyle) {
        isScrollEnabled = false
    }
    
    public func setupAttributes(style: TextStyle) {
        self.font = style.font
        self.textColor = style.textColor
    }
}

extension MetaTextAreaView: TextStyleConfigurable {
    
    public convenience init(style: TextStyle) {
        self.init()
        
        setupLayout(style: style)
        setupAttributes(style: style)
    }
    
    public func setupLayout(style: TextStyle) {
        // do nothing
    }
    
    public func setupAttributes(style: TextStyle) {
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
