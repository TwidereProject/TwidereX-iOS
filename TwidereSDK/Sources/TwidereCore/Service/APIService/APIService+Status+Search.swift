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
import CoreDataStack
import Alamofire
import TwitterSDK
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    static let defaultSearchCount = 20
    static let conversationSearchCount = 50
    
    // conversation tweet search
//    func tweetsSearch(
//        conversationRootTweetID: Twitter.Entity.Tweet.ID,
//        authorUsername: String,
//        maxID: String?,
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
//        let query = Twitter.API.Timeline.TimelineQuery(
//            count: APIService.conversationSearchCount,
//            maxID: maxID,
//            sinceID: conversationRootTweetID,
//            query: "to:\(authorUsername) OR from:\(authorUsername) -filter:retweets"
//        )
//        return _tweetsSearch(
//            query: query,
//            twitterAuthenticationBox: twitterAuthenticationBox
//        )
//    }
    
    // global tweet search
//    func tweetsSearch(
//        searchText: String,
//        maxID: String?,
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
//        let query = Twitter.API.Timeline.TimelineQuery(
//            count: APIService.defaultSearchCount,
//            maxID: maxID,
//            query: searchText
//        )
//        return _tweetsSearch(
//            query: query,
//            twitterAuthenticationBox: twitterAuthenticationBox
//        )
//    }

//    private func _tweetsSearch(
//        query: Twitter.API.Timeline.TimelineQuery,
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> {
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//
//        return Twitter.API.Search.tweets(
//            session: session,
//            authorization: authorization,
//            query: query
//        )
//        .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.Search.Content>, Error> in
//            let log = OSLog.api
//            let persistResponse = response.map { $0.statuses ?? [] }
//            return APIService.Persist.persistTweets(
//                managedObjectContext: self.backgroundManagedObjectContext,
//                query: query,
//                response: persistResponse,
//                persistType: .searchList,
//                requestTwitterUserID: requestTwitterUserID,
//                log: log
//            )
//            .setFailureType(to: Error.self)
//            .tryMap { result -> Twitter.Response.Content<Twitter.API.Search.Content> in
//                switch result {
//                case .success:
//                    return response
//                case .failure(let error):
//                    throw error
//                }
//            }
//            .eraseToAnyPublisher()
//        }
//        .switchToLatest()
//        .eraseToAnyPublisher()
//    }
    
}

// MARK: - Twitter
extension APIService {
    
    // for search
    func searchTwitterStatus(
        searchText: String,
        nextToken: String?,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Search.Content> {
        let query = Twitter.API.V2.Search.RecentTweetQuery(
            query: searchText,
            maxResults: APIService.defaultSearchCount,
            sinceID: nil,
            startTime: nil,
            nextToken: nextToken
        )
        return try await searchTwitterStatus(
            query: query,
            authenticationContext: authenticationContext
        )
    }
    
    // for thread
    public func searchTwitterStatus(
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
        return try await searchTwitterStatus(
            query: query,
            authenticationContext: authenticationContext
        )
    }
    
    public func searchTwitterStatus(
        query: Twitter.API.V2.Search.RecentTweetQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Search.Content> {
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
            let user = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // let statusCache = Persistence.PersistCache<TwitterStatus>()
            // let userCache = Persistence.PersistCache<TwitterUser>()
            
            Persistence.Twitter.persist(
                in: managedObjectContext,
                context: Persistence.Twitter.PersistContextV2(
                    dictionary: dictionary,
                    user: user,
                    statusCache: nil, // statusCache,
                    userCache: nil, // userCache,
                    networkDate: response.networkDate
                )
            )
        }   // end .performChanges { … }
        
        return response
    }
    
}
