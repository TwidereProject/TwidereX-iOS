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

extension APIService {
    
    // V2
    func tweetsRecentSearch(conversationID: Twitter.Entity.TweetV2.ConversationID, authorID: Twitter.Entity.User.ID, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<Twitter.API.RecentSearch.Content>, Error> {
        let query = "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))"
        return Twitter.API.RecentSearch.tweetsSearchRecent(query: query, maxResults: 100, session: session, authorization: authorization)
            .handleEvents(receiveOutput: { response in
                let content = response.value
                guard content.meta.resultCount > 0 else { return }
                
                var tweetsDict: [Twitter.Entity.TweetV2.ID: Twitter.Entity.TweetV2] = [:]
                for tweet in content.data ?? [] {
                    guard tweetsDict[tweet.id] == nil else {
                        assertionFailure()
                        continue
                    }
                    tweetsDict[tweet.id] = tweet
                }
                for tweet in content.includes?.tweets ?? [] {
                    guard tweetsDict[tweet.id] == nil else {
                        assertionFailure()
                        continue
                    }
                    tweetsDict[tweet.id] = tweet
                }
                
                var usersDict: [Twitter.Entity.UserV2.ID: Twitter.Entity.UserV2] = [:]
                for user in content.includes?.users ?? [] {
                    guard usersDict[user.id] == nil else {
                        assertionFailure()
                        continue
                    }
                    
                    usersDict[user.id] = user
                }
            })
            .eraseToAnyPublisher()
        
    }
    
}

