//
//  APIService+Tweet+Search.swift
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
    
    static let defaultSearchCount = 20
    static let conversationSearchCount = 50
    
    // convsersation tweet search
    func tweetsSearch(
        conversationRootTweetID: Twitter.Entity.Tweet.ID,
        authorUsername: String,
        maxID: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
        let query = Twitter.API.Timeline.Query(
            count: APIService.conversationSearchCount,
            maxID: maxID,
            sinceID: conversationRootTweetID,
            query: "to:\(authorUsername) OR from:\(authorUsername) -filter:retweets"
        )
        return _tweetsSearch(
            query: query,
            twitterAuthenticationBox: twitterAuthenticationBox
        )
    }
    
    // global tweet search
    func tweetsSearch(
        searchText: String,
        maxID: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
        let query = Twitter.API.Timeline.Query(
            count: APIService.defaultSearchCount,
            maxID: maxID,
            query: searchText
        )
        return _tweetsSearch(
            query: query,
            twitterAuthenticationBox: twitterAuthenticationBox
        )
    }

    private func _tweetsSearch(
        query: Twitter.API.Timeline.Query,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        
        return Twitter.API.Search.tweets(
            session: session,
            authorization: authorization,
            query: query
        )
        .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> in
            let log = OSLog.api
            let persistResponse = response.map { $0.statuses ?? [] }
            return APIService.Persist.persistTweets(
                managedObjectContext: self.backgroundManagedObjectContext,
                query: query,
                response: persistResponse,
                persistType: .searchList,
                requestTwitterUserID: requestTwitterUserID,
                log: log
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Twitter.Response.Content<Twitter.API.Search.Content> in
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

// V2
extension APIService {
    
    // convsersation tweet search
    func tweetsRecentSearch(
        conversationID: Twitter.Entity.V2.Tweet.ConversationID,
        authorID: Twitter.Entity.User.ID,
        sinceID: Twitter.Entity.V2.Tweet.ID?,
        startTime: Date?,
        nextToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> {

        
        let query = Twitter.API.V2.RecentSearch.Query(
            query: "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))",
            maxResults: APIService.conversationSearchCount,
            sinceID: sinceID,
            startTime: startTime,
            nextToken: nextToken
        )
        return _tweetsRecentSearch(
            query: query,
            twitterAuthenticationBox: twitterAuthenticationBox
        )
    }
    
    // global tweet search
    func tweetsRecentSearch(
        searchText: String,
        nextToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> {

        let query = Twitter.API.V2.RecentSearch.Query(
            query: searchText,
            maxResults: APIService.defaultSearchCount,
            sinceID: nil,
            startTime: nil,
            nextToken: nextToken
        )
        return _tweetsRecentSearch(
            query: query,
            twitterAuthenticationBox: twitterAuthenticationBox
        )
    }
    
    private func _tweetsRecentSearch(
        query: Twitter.API.V2.RecentSearch.Query,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.RecentSearch.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization

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
            // App will fallback to v1 API if get rate limit error
    }

    
}
