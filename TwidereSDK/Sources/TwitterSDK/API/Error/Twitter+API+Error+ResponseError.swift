//
//  Twitter+API+ResponseError.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-25.
//

import Foundation
import NIOHTTP1

extension Twitter.API.Error {
    public struct ResponseError: Error {
        public var httpResponseStatus: HTTPResponseStatus
        public var twitterAPIError: TwitterAPIError?
    
        public init(httpResponseStatus: HTTPResponseStatus, twitterAPIError: Twitter.API.Error.TwitterAPIError?) {
            self.httpResponseStatus = httpResponseStatus
            self.twitterAPIError = twitterAPIError
        }
    }
}
