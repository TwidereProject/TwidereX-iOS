//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-25.
//

import Foundation

// Ref: https://developer.twitter.com/en/support/twitter-api/error-troubleshooting
// Ref: https://developer.twitter.com/ja/docs/basics/response-codes (prefer)
extension Twitter.API.Error {
    public enum TwitterAPIError: Error {
        
        case custom(code: Int, message: String)
        
        // 88 - Corresponds with HTTP 429. The request limit for this resource has been reached for the current rate limit window.
        case rateLimitExceeded
        
        // 136 - <No Document>
        case blockedFromViewingThisUserProfile
        
        // 162 - <No Document>
        case blockedFromRequestFollowingThisUser
        
        // 179 - Sorry, you are not authorized to see this status
        case notAuthorizedToSeeThisStatus

        // 326 - Corresponds with HTTP 403. The user should log in to https://twitter.com to unlock their account before the user token can be used.
        case accountIsTemporarilyLocked(message: String)
        
        init(code: Int, message: String = "") {
            switch code {
            case 88:        self = .rateLimitExceeded
            case 136:       self = .blockedFromViewingThisUserProfile
            case 162:       self = .blockedFromRequestFollowingThisUser
            case 179:       self = .notAuthorizedToSeeThisStatus
            case 326:       self = .accountIsTemporarilyLocked(message: message)
            default:        self = .custom(code: code, message: message)
            }
        }
        
        init?(errorResponse: Twitter.API.ErrorResponse) {
            guard let error = errorResponse.errors.first else {
                return nil
            }
            
            self.init(code: error.code, message: error.message)
        }
        
        init?(errorResponseV2: Twitter.API.ErrorResponseV2) {
            guard let error = errorResponseV2.errors.first else {
                return nil
            }
            
            if let title = error.title, title == "Authorization Error" {
                self = .notAuthorizedToSeeThisStatus
                return
            }
            
            return nil
        }
        
        init?(errorRequestResponse: Twitter.API.ErrorRequestResponse) {
            switch (errorRequestResponse.request, errorRequestResponse.error) {
            case (_, "Not authorized."):
                self = .notAuthorizedToSeeThisStatus
            default:
                return nil
            }
        }
    }
}
