//
//  APIService+RecentSearch.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterAPI
import CoreDataStack
import CommonOSLog

extension APIService {
    
    // V2
    func tweetsRecentSearch(
        conversationID: Twitter.Entity.V2.Tweet.ConversationID,
        authorID: Twitter.Entity.User.ID,
        sinceID: Twitter.Entity.V2.Tweet.ID?,
        startTime: Date?,
        nextToken: String?,
        authorization: Twitter.API.OAuth.Authorization,
        requestTwitterUserID: Twitter.Entity.V2.User.ID
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.RecentSearch.Content>, Error> {
        let query = "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))"
        return Twitter.API.RecentSearch.tweetsSearchRecent(query: query, maxResults: 100, sinceID: sinceID, startTime: startTime, nextToken: nextToken, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.RecentSearch.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                        users: response.includes?.users ?? [],
                        media: response.includes?.media ?? []
                    )
                }
                
                // persist data
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in
                        return response
                    }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

