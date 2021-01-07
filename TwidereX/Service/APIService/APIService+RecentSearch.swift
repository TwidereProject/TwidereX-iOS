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
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        
        let query = Twitter.API.V2.RecentSearch.Query(
            query: "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))",
            maxResults: 100,
            sinceID: sinceID,
            startTime: startTime,
            nextToken: nextToken
        )
        return Twitter.API.V2.RecentSearch.tweetsSearchRecent(query: query, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                        users: response.includes?.users ?? [],
                        media: response.includes?.media ?? [],
                        places: response.includes?.places ?? []
                    )
                }
                
                // persist data
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in return response }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func tweetsRecentSearch(
        searchText: String,
        nextToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.V2.RecentSearch.Query(
            query: searchText,
            maxResults: 20,
            sinceID: nil,
            startTime: nil,
            nextToken: nextToken
        )
        return Twitter.API.V2.RecentSearch.tweetsSearchRecent(query: query, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                        users: response.includes?.users ?? [],
                        media: response.includes?.media ?? [],
                        places: response.includes?.places ?? []
                    )
                }
                
                // persist data
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in return response }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let responseError = error as? Twitter.API.Error.ResponseError {
                        if case .rateLimitExceeded = responseError.twitterAPIError {
                            self.error.send(.explicit(.twitterResponseError(responseError)))
                        }
                    }
                case .finished:
                    break
                }
                
            })
            .eraseToAnyPublisher()
    }
    
}
