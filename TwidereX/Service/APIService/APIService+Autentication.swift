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
    
    func twitterRequestToken() -> AnyPublisher<Twitter.API.OAuth.RequestToken, Error> {
        return Twitter.API.OAuth.requestToken(session: session)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
