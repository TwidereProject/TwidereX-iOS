//
//  SidebarItem.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereAsset
import TwidereLocalization

enum SidebarItem: Hashable {
    case local              // Mastodon only
    case federated          // Mastodon only
    case messages
    case likes
    case history
    case lists
    case trends
    case drafts
    case settings
}

extension SidebarItem {
    
    var title: String {
        switch self {
        case .local:        return L10n.Scene.Local.title
        case .federated:    return L10n.Scene.Federated.title
        case .messages:     return L10n.Scene.Messages.title
        case .likes:        return L10n.Scene.Likes.title
        case .history:      return "History"        // TODO: i18n
        case .lists:        return L10n.Scene.Lists.title
        case .trends:       return L10n.Scene.Trends.title
        case .drafts:       return L10n.Scene.Drafts.title
        case .settings:     return L10n.Scene.Settings.title
        }
    }
    
    var image: UIImage {
        switch self {
        case .local:        return Asset.Human.person2.image.withRenderingMode(.alwaysTemplate)
        case .federated:    return Asset.ObjectTools.globe.image.withRenderingMode(.alwaysTemplate)
        case .messages:     return Asset.Communication.mail.image.withRenderingMode(.alwaysTemplate)
        case .likes:        return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        case .history:      return Asset.Arrows.clockArrowCirclepath.image.withRenderingMode(.alwaysTemplate)
        case .lists:        return Asset.TextFormatting.listBullet.image.withRenderingMode(.alwaysTemplate)
        case .trends:       return Asset.Arrows.trendingUp.image.withRenderingMode(.alwaysTemplate)
        case .drafts:       return Asset.ObjectTools.note.image.withRenderingMode(.alwaysTemplate)
        case .settings:     return Asset.Editing.sliderHorizontal3.image.withRenderingMode(.alwaysTemplate)
        }
    }
    
}
