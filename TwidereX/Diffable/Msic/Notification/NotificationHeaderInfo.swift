//
//  NotificationHeaderInfo.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Meta
import CoreDataStack

struct NotificationHeaderInfo {
    
    let iconImage: UIImage
    let iconImageTintColor: UIColor
    let textMetaContent: MetaContent
    
    init(
        iconImage: UIImage,
        iconImageTintColor: UIColor,
        textMetaContent: MetaContent
    ) {
        self.iconImage = iconImage
        self.iconImageTintColor = iconImageTintColor
        self.textMetaContent = textMetaContent
    }
    
    init?(
        type: MastodonNotificationType,
        user: MastodonUser
    ) {
        guard let iconImage = NotificationHeaderInfo.iconImage(type: type),
              let iconImageTintColor = NotificationHeaderInfo.iconImageTintColor(type: type),
              let textMetaContent = NotificationHeaderInfo.textMetaContent(type: type, user: user)
        else { return nil }
        
        self.init(
            iconImage: iconImage,
            iconImageTintColor: iconImageTintColor,
            textMetaContent: textMetaContent
        )
    }
    
}

extension NotificationHeaderInfo {
    static func iconImage(
        type: MastodonNotificationType
    ) -> UIImage? {
        switch type {
        case .follow:
            return Asset.Human.personExclamation.image.withRenderingMode(.alwaysTemplate)
        case .followRequest:
            return Asset.Human.personPlus.image.withRenderingMode(.alwaysTemplate)
        case .mention:
            return nil
        case .reblog:
            return Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate)
        case .favourite:
            return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        case .poll:
            return Asset.ObjectTools.poll.image.withRenderingMode(.alwaysTemplate)
        case .status:
            return nil
        case ._other:
            assertionFailure()
            return nil
        }
    }
    
    static func iconImageTintColor(type: MastodonNotificationType) -> UIColor? {
        switch type {
        case .follow:
            return .systemOrange
        case .followRequest:
            return Asset.Colors.Theme.daylight.color
        case .mention:
            return nil
        case .reblog:
            return Asset.Colors.Theme.daylight.color
        case .favourite:
            return Asset.Colors.Tint.pink.color
        case .poll:
            return Asset.Colors.Theme.daylight.color
        case .status:
            return nil
        case ._other:
            assertionFailure()
            return nil
        }
    }
    
    static func textMetaContent(
        type: MastodonNotificationType,
        user: MastodonUser
    ) -> MetaContent? {
        let text: String
        switch type {
        case .follow:
            text = L10n.Common.Notification.follow(user.name)
        case .followRequest:
            text = L10n.Common.Notification.followRequest(user.name)
        case .mention:
            return nil
        case .reblog:
            text = L10n.Common.Notification.reblog(user.name)
        case .favourite:
            text = L10n.Common.Notification.favourite(user.name)
        case .poll:
            text = L10n.Common.Notification.poll
        case .status:
            return nil
        case ._other:
            assertionFailure()
            return nil
        }
        return Meta.convert(from: .mastodon(string: text, emojis: user.emojis.asDictionary))
    }
}
