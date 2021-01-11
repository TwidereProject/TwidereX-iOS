//
//  Item+EmptyStateHeaderAttribute+TimelineHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-4.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension Item.EmptyStateHeaderAttribute {
    
    var iconImage: UIImage {
        switch reason {
        case .noTweetsFound:        return Asset.Indices.infoCircle.image.withRenderingMode(.alwaysTemplate)
        case .notAuthorized:        return Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        case .blocked:              return Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        case .suspended:            return Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var title: String {
        switch reason {
        case .noTweetsFound:        return L10n.Common.Alerts.NoTweetsFound.title
        case .notAuthorized:        return L10n.Common.Alerts.PermissionDeniedNotAuthorized.title
        case .blocked:              return L10n.Common.Alerts.PermissionDeniedFriendshipBlocked.title
        case .suspended:            return L10n.Common.Alerts.AccountSuspended.title
        }
    }
    
    var message: String {
        switch reason {
        case .noTweetsFound:        return " "
        case .notAuthorized:        return L10n.Common.Alerts.PermissionDeniedNotAuthorized.message
        case .blocked:              return L10n.Common.Alerts.PermissionDeniedFriendshipBlocked.message
        case .suspended:
            let twitterRules = L10n.Common.Alerts.AccountSuspended.twitterRules
            return L10n.Common.Alerts.AccountSuspended.message(twitterRules)
        }
    }
    
}

extension TimelineHeaderView {
    static func configure(timelineHeaderView: TimelineHeaderView, attribute: Item.EmptyStateHeaderAttribute) {
        timelineHeaderView.iconImageView.image = attribute.iconImage
        timelineHeaderView.titleLabel.text = attribute.title
        timelineHeaderView.messageLabel.text = attribute.message
    }
}
