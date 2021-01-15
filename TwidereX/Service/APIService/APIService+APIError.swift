//
//  APIService+APIError.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwitterAPI
import SwiftMessages

extension APIService {
    enum APIError: Error {
        
        case implicit(ErrorReason)
        case explicit(ErrorReason)
        
        enum ErrorReason {
            // application internal error
            case twitterInternalError(Twitter.API.Error.InternalError)
            case authenticationMissing
            case badRequest
            case requestThrottle
            
            // Twitter API error
            case twitterResponseError(Twitter.API.Error.ResponseError)
        }
        
    }
}

extension APIService.APIError.ErrorReason: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .twitterInternalError(let error):
            return error.errorDescription
        case .authenticationMissing:
            return "Authentication Missing"
        case .badRequest:
            return "Bad Request"
        case .requestThrottle:
            return "Request Throttle"
        case .twitterResponseError(let error):
            guard let twitterAPIError = error.twitterAPIError else {
                return error.httpResponseStatus.reasonPhrase
            }
            
            switch twitterAPIError {
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
            case .custom(let code, _):
                return "Code \(code)"
            }
        }
    }
    
    var failureReason: String? {
        switch self {
        case .twitterInternalError(let error):
            return error.failureReason
        case .authenticationMissing:
            return "Authentication not found"
        case .badRequest:
            return "The request is invalid"
        case .requestThrottle:
            return "The requests are too frequent"
        case .twitterResponseError(let error):
            guard let twitterAPIError = error.twitterAPIError else {
                return nil
            }
            
            switch twitterAPIError {
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
            case .custom(let code, _):
                return "Code \(code)"
            }
        }
    }
    
}

extension APIService.APIError.ErrorReason {
    
    var messageConfig: SwiftMessages.Config {
        var config = SwiftMessages.defaultConfig
        config.interactiveHide = true
        
        switch self {
        case .twitterInternalError:
            config.duration = .seconds(seconds: 5)
        case .authenticationMissing:
            config.duration = .seconds(seconds: 5)
        case .badRequest:
            config.duration = .seconds(seconds: 5)
        case .requestThrottle:
            config.duration = .seconds(seconds: 5)
        case .twitterResponseError(let error):
            switch error.twitterAPIError {
            case .userHasBeenSuspended:
                config.duration = .seconds(seconds: 5)
            case .rateLimitExceeded:
                config.duration = .seconds(seconds: 5)
            case .blockedFromViewingThisUserProfile:
                config.duration = .seconds(seconds: 5)
            case .blockedFromRequestFollowingThisUser:
                config.duration = .seconds(seconds: 5)
            case .notAuthorizedToSeeThisStatus:
                config.duration = .seconds(seconds: 5)
            case .accountIsTemporarilyLocked:
                config.duration = .seconds(seconds: 10)
            case .custom:
                config.duration = .seconds(seconds: 5)
            case .none:
                config.duration = .seconds(seconds: 5)
            }
        }
        
        return config
    }

    var notifyBannerView: NotifyBannerView {
        let bannerView = NotifyBannerView()
        bannerView.titleLabel.text = errorDescription
        bannerView.messageLabel.text = failureReason
        
        switch self {
        case .twitterInternalError:
            bannerView.configure(for: .warning)
        case .authenticationMissing:
            bannerView.configure(for: .warning)
        case .badRequest:
            bannerView.configure(for: .warning)
        case .requestThrottle:
            bannerView.configure(for: .warning)
        case .twitterResponseError(let error):
            switch error.twitterAPIError {
            case .userHasBeenSuspended:
                bannerView.configure(for: .warning)
            case .rateLimitExceeded:
                bannerView.configure(for: .warning)
            case .blockedFromViewingThisUserProfile:
                bannerView.configure(for: .error)
            case .blockedFromRequestFollowingThisUser:
                bannerView.configure(for: .error)
            case .notAuthorizedToSeeThisStatus:
                bannerView.configure(for: .error)
            case .accountIsTemporarilyLocked:
                bannerView.configure(for: .error)
                bannerView.actionButtonTapHandler = { _ in
                    let url = URL(string: "https://twitter.com/account/access")!
                    UIApplication.shared.open(url)
                }
            case .custom:
                bannerView.configure(for: .error)
            case .none:
                bannerView.configure(for: .error)
            }
        }
        
        return bannerView
    }
    
}
