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
    func tweetsRecentSearch(conversationID: Twitter.Entity.V2.Tweet.ConversationID, authorID: Twitter.Entity.User.ID, authorization: Twitter.API.OAuth.Authorization, requestTwitterUserID: Twitter.Entity.V2.User.ID) -> AnyPublisher<Twitter.Response.Content<Twitter.API.RecentSearch.Content>, Error> {
        let query = "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))"
        return Twitter.API.RecentSearch.tweetsSearchRecent(query: query, maxResults: 100, session: session, authorization: authorization)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }

                let log = OSLog.api
                
                guard response.value.meta.resultCount > 0 else {
                    return
                }
                let response = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                        users: response.includes?.users ?? []
                    )
                }

                // persist data
                APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: response, requestTwitterUserID: requestTwitterUserID, log: log)
            })
            .eraseToAnyPublisher()
        
    }
    
}

