//
//  Item+EmptyStateHeaderAttribute+TimelineHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-4.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

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

        let message = attribute.message
        timelineHeaderView.messageLabel.activeEntities.removeAll()
        timelineHeaderView.messageLabel.text = message
        switch attribute.reason {
        case .suspended:
            let twitterRules = L10n.Common.Alerts.AccountSuspended.twitterRules
            let twitterRulesURL = URL(string: "https://support.twitter.com/articles/18311")!
            if let range = message.range(of: twitterRules) {
                let activeEntities: [ActiveEntity] = [
                    ActiveEntity(range: NSRange(range, in: message), type: .url(original: twitterRulesURL.absoluteString, trimmed: twitterRulesURL.absoluteString))
                ]
                timelineHeaderView.messageLabel.activeEntities = activeEntities
            }
        default:
            break
        }
    }
}
