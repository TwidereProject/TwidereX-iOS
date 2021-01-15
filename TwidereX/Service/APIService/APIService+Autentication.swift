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
    
    func twitterRequestToken() -> AnyPublisher<Twitter.API.OAuth.OAuthRequestTokenExchange, Error> {
        let oauthExchangeProvider = AppSecret.shared
        return Twitter.API.OAuth.requestToken(session: session, oauthExchangeProvider: oauthExchangeProvider)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func twitterAccessToken(requestToken: String, pinCode: String) -> AnyPublisher<Twitter.API.OAuth.AccessTokenResponse, Error> {
        let oauthSecret = AppSecret.shared.oauthSecret
        return Twitter.API.OAuth.accessToken(session: session, consumerKey: oauthSecret.consumerKey, consumerSecret: oauthSecret.consumerKeySecret, requestToken: requestToken, pinCode: pinCode)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
