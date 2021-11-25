//
//  APIService+Lookup.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import os.log
import Foundation
import Combine
import TwitterSDK
import CoreDataStack
import CommonOSLog
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    // V1
//    @available(*, deprecated, message: "")
//    func statuses(
//        tweetIDs: [Twitter.Entity.Tweet.ID],
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//        let query = Twitter.API.Lookup.Query(ids: tweetIDs)
//        return Twitter.API.Lookup.tweets(session: session, authorization: authorization, query: query)
//            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
//                let log = OSLog.api
//
//                let managedObjectContext = self.backgroundManagedObjectContext
//                return APIService.Persist.persistTweets(
//                    managedObjectContext: managedObjectContext,
//                    query: nil,
//                    response: response,
//                    persistType: .lookUp,
//                    requestTwitterUserID: requestTwitterUserID,
//                    log: log
//                )
//                .setFailureType(to: Error.self)
//                .tryMap { result -> Twitter.Response.Content<[Twitter.Entity.Tweet]> in
//                    switch result {
//                    case .success:
//                        return response
//                    case .failure(let error):
//                        throw error
//                    }
//                }
//                .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .eraseToAnyPublisher()
//    }

    // V2
//    @available(*, deprecated, message: "")
//    func tweets(
//        tweetIDs: [Twitter.Entity.V2.Tweet.ID],
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Lookup.Content>, Error> {
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        return Twitter.API.V2.Lookup.tweets(tweetIDs: tweetIDs, session: session, authorization: authorization)
//            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Lookup.Content>, Error> in
//                let log = OSLog.api
//
//                let dictResponse = response.map { response in
//                    return Twitter.Response.V2.DictContent(
//                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
//                        users: response.includes?.users ?? [],
//                        media: response.includes?.media ?? [],
//                        places: response.includes?.places ?? []
//                    )
//                }
//
//                // persist data
//                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
//                    .map { _ in return response }
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .eraseToAnyPublisher()
//    }

}

extension APIService {
    // V2
    public func twitterStatus(
        statusIDs: [Twitter.Entity.V2.Tweet.ID],
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Lookup.Content> {
        let query = Twitter.API.V2.Lookup.StatusLookupQuery(statusIDs: statusIDs)
        
        let response = try await Twitter.API.V2.Lookup.statuses(
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
            let statusCache = Persistence.PersistCache<TwitterStatus>()
            let userCache = Persistence.PersistCache<TwitterUser>()
            
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
