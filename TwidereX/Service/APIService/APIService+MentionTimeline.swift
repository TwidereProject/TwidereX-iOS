//
//  APIService+MentionTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    func twitterMentionTimeline(
        count: Int = 200,
        maxID: String? = nil,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Timeline.Query(count: count, maxID: maxID)
        
        return Twitter.API.Timeline.mentionTimeline(session: session, authorization: authorization, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
                let log = OSLog.api
                return APIService.Persist.persistTimeline(
                    managedObjectContext: self.backgroundManagedObjectContext,
                    query: query,
                    response: response,
                    persistType: .mentionTimeline,
                    requestTwitterUserID: requestTwitterUserID,
                    log: log
                )
                .setFailureType(to: Error.self)
                .tryMap { result -> Twitter.Response.Content<[Twitter.Entity.Tweet]> in
                    switch result {
                    case .success:
                        return response
                    case .failure(let error):
                        throw error
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}
