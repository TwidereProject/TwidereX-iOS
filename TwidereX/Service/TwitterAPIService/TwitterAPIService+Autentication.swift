//
//  TwitterAPIService+Autentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-2.
//

import Foundation
import Combine
import TwitterAPI

extension TwitterAPIService {
    
    func requestToken() -> AnyPublisher<TwitterAPI.OAuth.RequestToken, Error> {
        return TwitterAPI.OAuth.requestToken(session: session)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
