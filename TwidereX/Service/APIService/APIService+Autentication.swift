//
//  APIService+Autentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-2.
//

import Foundation
import Combine
import TwitterSDK
import AppShared

extension APIService {
    
    func twitterRequestToken(
        provider: TwitterOAuthExchangeProvider
    ) async throws -> Twitter.API.OAuth.OAuthRequestTokenResponseExchange {
        let oauthExchange = provider.oauthExchange()
        return try await Twitter.API.OAuth.requestToken(session: session, oauthExchange: oauthExchange)
    }
    
    // only pin-based OAuth needs client swap AccessToken
    func twitterAccessToken(requestToken: String, pinCode: String, oauthSecret: AppSecret.OAuthSecret) -> AnyPublisher<Twitter.API.OAuth.AccessTokenResponse, Error> {
        return Twitter.API.OAuth.accessToken(session: session, consumerKey: oauthSecret.consumerKey, consumerSecret: oauthSecret.consumerKeySecret, requestToken: requestToken, pinCode: pinCode)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
