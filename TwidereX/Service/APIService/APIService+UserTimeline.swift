//
//  APIService+UserTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {

    func twitterUserTimeline(count: Int = 200, userID: String, maxID: String? = nil, authorization: Twitter.API.OAuth.Authorization, twitterUserID: TwitterUser.UserID) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        let query = Twitter.API.Timeline.Query(count: count, userID: userID, maxID: maxID, excludeReplies: false)
        return Twitter.API.Timeline.userTimeline(session: session, authorization: authorization, query: query)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }

                let log = OSLog.api

                APIService.persistTimeline(managedObjectContext: self.backgroundManagedObjectContext, query: query, response: response, persistType: .userTimeline, requestTwitterUserID: twitterUserID, log: log)
            })
            .eraseToAnyPublisher()
    }
    
}
