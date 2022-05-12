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
    public func twitterStatusV1(
        statusIDs: [Twitter.Entity.Tweet.ID],
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let query = Twitter.API.Lookup.LookupQuery(ids: statusIDs)
        let response = try await Twitter.API.Lookup.tweets(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for entity in response.value {
                _ = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterStatus.PersistContext(
                        entity: entity,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                    
                )
            }
        }   // end .performChanges { … }
        
        return response
    }

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
