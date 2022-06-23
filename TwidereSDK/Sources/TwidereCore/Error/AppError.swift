//
//  AppError.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwitterSDK
import MastodonSDK
import TwidereLocalization

public enum AppError: Error {
    
    case implicit(ErrorReason)
    case explicit(ErrorReason)
    
    public enum ErrorReason {
        // application internal error
        case `internal`(reason: String)
        case twitterInternalError(Twitter.API.Error.InternalError)
        case authenticationMissing
        case badRequest
        case requestThrottle
        
        // Twitter API error
        case twitterResponseError(Twitter.API.Error.ResponseError)
        // Mastodon API error
        case mastodonResponseError(Mastodon.API.Error)
    }
    
}

extension AppError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .implicit(let errorReason):    return errorReason.errorDescription
        case .explicit(let errorReason):    return errorReason.errorDescription
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .implicit(let errorReason):    return errorReason.failureReason
        case .explicit(let errorReason):    return errorReason.failureReason
        }
    }
    
}

extension AppError.ErrorReason: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .internal(let reason):
            return "Internal"
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
            
            return twitterAPIError.errorDescription
        case .mastodonResponseError(let error):
            guard let mastodonError = error.mastodonError else {
                return error.httpResponseStatus.reasonPhrase
            }
            
            return mastodonError.errorDescription
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .internal(let reason):
            return reason
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
            
            return twitterAPIError.failureReason
        case .mastodonResponseError(let error):
            guard let mastodonError = error.mastodonError else {
                return nil
            }
            
            return mastodonError.failureReason
        }
    }
    
}
