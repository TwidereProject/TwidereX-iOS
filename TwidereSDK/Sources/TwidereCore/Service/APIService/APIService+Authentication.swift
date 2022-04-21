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
import TwidereCommon

extension APIService {
    
    public func twitterOAuthRequestToken(
        provider: TwitterOAuthProvider
    ) async throws -> Twitter.API.OAuth.RequestTokenResponseContext {
        return try await Twitter.API.OAuth.requestToken(
            session: session,
            query: provider.oauth
        )
    }
    
    // PIN-based OAuth needs client swap AccessToken
    public func twitterOAuthAccessToken(
        query: Twitter.API.OAuth.AccessToken.AccessTokenQuery
    ) async throws -> Twitter.API.OAuth.AccessToken.AccessTokenResponse {
        return try await Twitter.API.OAuth.AccessToken.accessToken(
            session: session,
            query: query
        )
    }
    
    public func twitterOAuth2AccessToken(
        query: Twitter.API.V2.OAuth2.AccessTokenQuery
    ) async throws -> Twitter.API.V2.OAuth2.AccessTokenResponse {
        return try await Twitter.API.V2.OAuth2.accessToken(
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
