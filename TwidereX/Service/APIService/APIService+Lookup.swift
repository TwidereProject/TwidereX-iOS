//
//  APIService+Lookup.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation
import Combine
import TwitterAPI
import CoreDataStack

extension APIService {

    func tweetLookup(tweets: [Twitter.Entity.Tweet.ID], authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<[Twitter.Entity.TweetV2]>, Error> {
        Twitter.API.Lookup.lookup(tweets: tweets, session: session, authorization: authorization)
    }
    
}
