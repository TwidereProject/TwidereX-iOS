//
//  APIService+Geo.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
 
    public func geoSearch(
        latitude: Double,
        longitude: Double,
        granularity: String,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Place]> {
        let authorization = twitterAuthenticationContext.authorization
        let query = Twitter.API.Geo.SearchQuery(
            latitude: latitude,
            longitude: longitude,
            granularity: granularity
        )
        let response = try await Twitter.API.Geo.search(
            session: session,
            query: query,
            authorization: authorization
        )
        
        return response.map { $0.result.places }
    }
    
}
