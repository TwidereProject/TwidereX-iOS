//
//  APIService+UserTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import TwitterAPI

extension APIService {

    func twitterUserTimeline(userID: String, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        let query = Twitter.API.Timeline.Query(count: 200, userID: userID, excludeReplies: false)
        return Twitter.API.Timeline.userTimeline(session: session, authorization: authorization, query: query)
    }
    
}
