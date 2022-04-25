//
//  APIService+Trend+Place.swift
//  
//
//  Created by MainasuK on 2022-4-15.
//

import Foundation
import TwitterSDK

extension APIService {
    public func twitterTrendPlaces(
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Trend.Place]> {
        let response = try await Twitter.API.Trend.places(
            session: session,
            authorization: authenticationContext.authorization
        )
        return response
    }
}
