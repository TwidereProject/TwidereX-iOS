//
//  APIService+Trend.swift
//  
//
//  Created by MainasuK on 2021-12-28.
//

import Foundation
import TwitterSDK
import MastodonSDK

extension APIService {
    public func twitterTrend(
        placeID: Int,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.API.Trend.TopicResponse]> {
        let query = Twitter.API.Trend.TopicQuery(id: placeID)
        let response = try await Twitter.API.Trend.topics(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        return response
    }
}

extension APIService {
    public func mastodonTrend(
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let query = Mastodon.API.Trend.TrendQuery(limit: 10)
        let response = try await Mastodon.API.Trend.tags(
            session: session,
            domain: authenticationContext.domain,
            query: query
        )
        return response
    }
}
