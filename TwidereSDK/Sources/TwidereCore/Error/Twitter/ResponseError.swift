//
//  ResponseError.swift
//  
//
//  Created by MainasuK on 2022-1-14.
//

import Foundation
import TwitterSDK
import TwidereLocalization

extension Twitter.API.Error.ResponseError: LocalizedError {
    
    public var errorDescription: String? {
        return twitterAPIError?.errorDescription ?? httpResponseStatus.reasonPhrase
    }
    
    public var failureReason: String? {
        return twitterAPIError?.failureReason
    }
    
}
