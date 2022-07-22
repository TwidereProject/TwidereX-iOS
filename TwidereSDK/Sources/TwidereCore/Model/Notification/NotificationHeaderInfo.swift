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
import TwidereAsset
import TwidereLocalization
import MetaTextKit

public struct NotificationHeaderInfo {
    
    public let iconImage: UIImage
    public let iconImageTintColor: UIColor
    public let textMetaContent: MetaContent
    
    public init(
        iconImage: UIImage,
        iconImageTintColor: UIColor,
        textMetaContent: MetaContent
    ) {
        self.iconImage = iconImage
        self.iconImageTintColor = iconImageTintColor
        self.textMetaContent = textMetaContent
    }
    
    public init?(
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
    public static func iconImage(
        type: MastodonNotificationType
    ) -> UIImage? {
        switch type {
        case .follow:
            return Asset.Human.personExclamationMini.image.withRenderingMode(.alwaysTemplate)
        case .followRequest:
            return Asset.Human.personPlusMini.image.withRenderingMode(.alwaysTemplate)
        case .mention:
            return nil
        case .reblog:
            return Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate)
        case .favourite:
            return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        case .poll:
            return Asset.ObjectTools.pollMini.image.withRenderingMode(.alwaysTemplate)
        case .status:
            return nil
        case ._other:
            // assertionFailure()
            return nil
        }
    }
    
    public static func iconImageTintColor(type: MastodonNotificationType) -> UIColor? {
        return .label
    }
    
    public static func textMetaContent(
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
            // assertionFailure()
            return nil
        }
        return Meta.convert(from: .mastodon(string: text, emojis: user.emojis.asDictionary))
    }
}
