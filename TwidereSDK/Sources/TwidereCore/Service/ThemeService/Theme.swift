//
//  Theme.swift
//  
//
//  Created by MainasuK on 2023-09-19.
//

import UIKit
import TwidereAsset
import Disk

public struct Theme: Hashable {
    public let identifier: Identifier
    public let interfaceStyle: UIUserInterfaceStyle
    public let background: UIColor
    public let foreground: UIColor
    public let comment: UIColor
    public let commentDisabled: UIColor
    public let highlight: UIColor
    public let like: UIColor
    public let repost: UIColor
    public let bookmark: UIColor
    public let line: UIColor
}

extension Theme {
    public var barBackgroundColor: UIColor? {
        switch identifier {
        case .system: return nil
        default: return background.withAlphaComponent(0.8)
        }
    }
}

extension Theme {
    public enum Identifier: Hashable {
        case system
        case grandBudapestHotel
        case custom(id: String)
    }
}

extension Theme {
    static var system: Theme {
        Theme(
            identifier: .system,
            interfaceStyle: .unspecified,
            background: .systemBackground,
            foreground: .label,
            comment: .secondaryLabel,
            commentDisabled: .systemGray,
            highlight: .tintColor,
            like: .systemRed,
            repost: .systemBlue,
            bookmark: .systemYellow,
            line: .separator
        )
    }
    
    static var grandBudapestHotel: Theme {
        Theme(
            identifier: .grandBudapestHotel,
            interfaceStyle: .unspecified,
            background: Asset.Theme.GrandBudapestHotel.background.color,
            foreground: Asset.Theme.GrandBudapestHotel.foreground.color,
            comment: Asset.Theme.GrandBudapestHotel.comment.color,
            commentDisabled: Asset.Theme.GrandBudapestHotel.commentDisabled.color,
            highlight: Asset.Theme.GrandBudapestHotel.highlight.color,
            like: Asset.Theme.GrandBudapestHotel.like.color,
            repost: Asset.Theme.GrandBudapestHotel.repost.color,
            bookmark: Asset.Theme.GrandBudapestHotel.bookmark.color,
            line: Asset.Theme.GrandBudapestHotel.line.color
        )
    }
}

extension UIUserInterfaceStyle: Codable { }
