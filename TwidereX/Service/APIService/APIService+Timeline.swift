//
//  APIService+Timeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import Foundation
import Combine
import TwitterAPI
import CoreDataStack

extension APIService {
    func twitterHomeTimeline(twitterAuthentication authentication: TwitterAuthentication) -> AnyPublisher<[Twitter.Entity.Tweet], Error> {
        let authorization = Twitter.API.OAuth.Authorization(
            consumerKey: authentication.consumerKey,
            consumerSecret: authentication.consumerSecret,
            accessToken: authentication.accessToken,
            accessTokenSecret: authentication.accessTokenSecret
        )
        
        os_log("%{public}s[%{public}ld], %{public}s: fetch home timeline…", ((#file as NSString).lastPathComponent), #line, #function)

        return Twitter.API.Timeline.homeTimeline(session: session, authorization: authorization)
            .handleEvents(receiveOutput: { tweets in
                os_log("%{public}s[%{public}ld], %{public}s: fetch %ld tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count)
                // TODO: use background context insert and merge change
            })
            .eraseToAnyPublisher()
    }
}
