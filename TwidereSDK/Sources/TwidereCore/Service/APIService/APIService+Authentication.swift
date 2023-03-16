//
//  APIService+Authentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-2.
//

import Foundation
import Combine
import TwitterSDK
import MastodonSDK

extension APIService {
    
    // PIN-based OAuth needs client swap AccessToken
    public func twitterOAuthAccessToken(
        query: Twitter.API.OAuth.AccessToken.AccessTokenQuery
    ) async throws -> Twitter.API.OAuth.AccessToken.AccessTokenResponse {
        return try await Twitter.API.OAuth.AccessToken.accessToken(
            session: session,
            query: query
        )
    }
    
}

extension APIService {
    public func mastodonUserAccessToken(
        domain: String,
        query: Mastodon.API.OAuth.AccessTokenQuery
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Token> {
        return try await Mastodon.API.OAuth.accessToken(
            session: session,
            domain: domain,
            query: query
        )
    }
}
