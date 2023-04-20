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
import MastodonSDK
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
                places: content.includes?.places ?? [],
                polls: content.includes?.polls ?? []
            )
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            _ = Persistence.Twitter.persist(
                in: managedObjectContext,
                context: Persistence.Twitter.PersistContextV2(
                    dictionary: dictionary,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }   // end .performChanges { … }
        
        return response
    }
}

extension APIService {
    public func mastodonStatus(
        statusID: Mastodon.Entity.Status.ID,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let domain = authenticationContext.domain
        let authorization = authenticationContext.authorization
        let managedObjectContext = backgroundManagedObjectContext

        let response = try await Mastodon.API.Status.lookup(
            session: session,
            domain: domain,
            query: Mastodon.API.Status.LookupStatusQuery(id: statusID),
            authorization: authorization
        )
        
        try await managedObjectContext.performChanges {
            let entity = response.value
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            _ = Persistence.MastodonStatus.createOrMerge(
                in: managedObjectContext,
                context: .init(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: me,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
}
