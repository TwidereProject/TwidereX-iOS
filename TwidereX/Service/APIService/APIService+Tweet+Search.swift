//
//  APIService+Tweet+Search.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import TwitterSDK
import CoreDataStack
import CommonOSLog
import Alamofire
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    static let defaultSearchCount = 20
    static let conversationSearchCount = 50
    
    // conversation tweet search
    func tweetsSearch(
        conversationRootTweetID: Twitter.Entity.Tweet.ID,
        authorUsername: String,
        maxID: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
        let query = Twitter.API.Timeline.TimelineQuery(
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
        let query = Twitter.API.Timeline.TimelineQuery(
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
        query: Twitter.API.Timeline.TimelineQuery,
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
    
    // conversation tweet search
    @available(*, deprecated, message: "")
    func tweetsRecentSearch(
        conversationID: Twitter.Entity.V2.Tweet.ConversationID,
        authorID: Twitter.Entity.User.ID,
        sinceID: Twitter.Entity.V2.Tweet.ID?,
        startTime: Date?,
        nextToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Search.Content>, Error> {

        let query = Twitter.API.V2.Search.RecentQuery(
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
    @available(*, deprecated, message: "")
    func tweetsRecentSearch(
        searchText: String,
        nextToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Search.Content>, Error> {

        let query = Twitter.API.V2.Search.RecentQuery(
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
    
    @available(*, deprecated, message: "")
    private func _tweetsRecentSearch(
        query: Twitter.API.V2.Search.RecentQuery,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Search.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization

        return Twitter.API.V2.Search.tweetsSearchRecent(query: query, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Search.Content>, Error> in
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

extension APIService {
    
    // for thread
    func searchTwitterStatus(
        conversationID: Twitter.Entity.V2.Tweet.ConversationID,
        authorID: Twitter.Entity.User.ID,
        sinceID: Twitter.Entity.V2.Tweet.ID?,
        startTime: Date?,
        nextToken: String?,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Search.Content> {
        let query = Twitter.API.V2.Search.RecentTweetQuery(
            query: "conversation_id:\(conversationID) (to:\(authorID) OR from:\(authorID))",
            maxResults: APIService.conversationSearchCount,
            sinceID: sinceID,
            startTime: startTime,
            nextToken: nextToken
        )
        let response = try await Twitter.API.V2.Search.recentTweet(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            // log rate limit
            response.logRateLimit()
            
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let content = response.value
            let dictionary = Twitter.Response.V2.DictContent(
                tweets: [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                users: content.includes?.users ?? [],
                media: content.includes?.media ?? [],
                places: content.includes?.places ?? []
            )
            let statusCache = Persist.PersistCache<TwitterStatus>()
            let userCache = Persist.PersistCache<TwitterUser>()
            
            Persistence.Twitter.persist(
                in: managedObjectContext,
                context: Persistence.Twitter.PersistContextV2(
                    dictionary: dictionary,
                    statusCache: nil, // statusCache,
                    userCache: nil, // userCache,
                    networkDate: response.networkDate
                )
            )
        }   // end .performChanges { … }
        
        return response
    }
    
}
