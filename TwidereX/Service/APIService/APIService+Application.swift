//
//  APIService+Application.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-7.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    public func rateLimitStatus(authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.RateLimitStatus>, Error> {
        return Twitter.API.Application.rateLimitStatus(session: session, authorization: authorization)
    }
    
}
