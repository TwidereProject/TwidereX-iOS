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
        let oauthExchangeProvider = AppSecret()
        return Twitter.API.OAuth.requestToken(session: session, oauthExchangeProvider: oauthExchangeProvider)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
