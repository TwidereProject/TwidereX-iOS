//
//  TwitterError.swift
//  
//
//  Created by MainasuK on 2022-1-14.
//

import Foundation
import TwitterSDK
import TwidereLocalization

extension Twitter.API.Error.TwitterAPIError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .userHasBeenSuspended:
            return L10n.Common.Alerts.AccountSuspended.title
        case .rateLimitExceeded:
            return L10n.Common.Alerts.RateLimitExceeded.title
        case .blockedFromViewingThisUserProfile:
            return L10n.Common.Alerts.PermissionDeniedNotAuthorized.title
        case .blockedFromRequestFollowingThisUser:
            return L10n.Common.Alerts.PermissionDeniedFriendshipBlocked.title
        case .notAuthorizedToSeeThisStatus:
            return L10n.Common.Alerts.PermissionDeniedNotAuthorized.title
        case .accountIsTemporarilyLocked:
            return L10n.Common.Alerts.AccountTemporarilyLocked.title
        case .custom:
            return nil
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .userHasBeenSuspended:
            let twitterRules = L10n.Common.Alerts.AccountSuspended.twitterRules
            return L10n.Common.Alerts.AccountSuspended.message(twitterRules)
        case .rateLimitExceeded:
            return L10n.Common.Alerts.RateLimitExceeded.message
        case .blockedFromViewingThisUserProfile:
            return L10n.Common.Alerts.PermissionDeniedNotAuthorized.message
        case .blockedFromRequestFollowingThisUser:
            return L10n.Common.Alerts.PermissionDeniedFriendshipBlocked.message
        case .notAuthorizedToSeeThisStatus:
            return L10n.Common.Alerts.PermissionDeniedNotAuthorized.message
        case .accountIsTemporarilyLocked:
            return L10n.Common.Alerts.AccountTemporarilyLocked.message
        case .custom(let code, let message):
            return "Code \(code) - \(message)"
        }
    }
    
}

