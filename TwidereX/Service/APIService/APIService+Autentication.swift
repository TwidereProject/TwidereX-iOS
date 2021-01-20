//
//  APIService+Autentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-2.
//

import Foundation
import Combine
import TwitterAPI

extension APIService {
    
    func twitterRequestToken(withOAuthExchangeProvider provider: OAuthExchangeProvider = AppSecret.default) -> AnyPublisher<Twitter.API.OAuth.OAuthRequestTokenExchange, Error> {
        let oauthExchangeProvider = provider
        return Twitter.API.OAuth.requestToken(session: session, oauthExchangeProvider: oauthExchangeProvider)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // only pin-based OAuth needs client swap AccessToken
    func twitterAccessToken(requestToken: String, pinCode: String, oauthSecret: AppSecret.OAuthSecret) -> AnyPublisher<Twitter.API.OAuth.AccessTokenResponse, Error> {
        return Twitter.API.OAuth.accessToken(session: session, consumerKey: oauthSecret.consumerKey, consumerSecret: oauthSecret.consumerKeySecret, requestToken: requestToken, pinCode: pinCode)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
