//
//  APIService+Authentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-2.
//

import Foundation
import Combine
import AppShared
import TwitterSDK
import MastodonSDK

extension APIService {
    
    func twitterRequestToken(
        provider: TwitterOAuthExchangeProvider
    ) async throws -> Twitter.API.OAuth.OAuthRequestTokenResponseExchange {
        let oauthExchange = provider.oauthExchange()
        return try await Twitter.API.OAuth.requestToken(session: session, oauthExchange: oauthExchange)
    }
    
    func twitterAccessToken() async throws {
        
    }
    
    // only pin-based OAuth needs client swap AccessToken
    func twitterAccessToken(
        requestToken: String,
        pinCode: String,
        oauthSecret: AppSecret.OAuthSecret
    ) async throws -> Twitter.API.OAuth.AccessTokenResponse {
        return try await Twitter.API.OAuth.accessToken(
            session: session,
            consumerKey: oauthSecret.consumerKey,
            consumerSecret: oauthSecret.consumerKeySecret,
            requestToken: requestToken,
            pinCode: pinCode
        )
    }
    
}

extension APIService {
    func mastodonUserAccessToken(
        domain: String,
        query: Mastodon.API.OAuth.AccessTokenQuery,
        code: String
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Token> {
        return try await Mastodon.API.OAuth.accessToken(session: session, domain: domain, query: query)
    }
}
