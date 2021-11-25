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
 
    func geoSearch(latitude: Double, longitude: Double, granularity: String, twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Place]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Geo.SearchQuery(latitude: latitude, longitude: longitude, granularity: granularity)
        return Twitter.API.Geo.search(session: session, authorization: authorization, query: query)
            .map { response in
                response.map { $0.result.places }
            }
            .eraseToAnyPublisher()
            
    }
    
}
