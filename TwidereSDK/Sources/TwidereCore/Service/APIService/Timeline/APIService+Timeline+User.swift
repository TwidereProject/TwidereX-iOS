//
//  APIService+UserTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    public func twitterUserTimeline(
        userID: Twitter.Entity.V2.User.ID,
        query: Twitter.API.V2.User.Timeline.TweetsQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Timeline.TweetsContent> {
        let response = try await Twitter.API.V2.User.Timeline.tweets(
            session: session,
            userID: userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let statusIDs: [Twitter.Entity.Tweet.ID] = {
            var ids: [Twitter.Entity.Tweet.ID] = []
            if let statuses = response.value.data {
                ids.append(contentsOf: statuses.map { $0.id })
            }
            if let statuses = response.value.includes?.tweets {
                ids.append(contentsOf: statuses.map { $0.id })
            }
            return Array(Set(ids))
        }()
        let _lookupResponse = try? await twitterBatchLookup(
            statusIDs: statusIDs,
            authenticationContext: authenticationContext
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
            
            // persist [TwitterStatus]
            let statusArray = Persistence.Twitter.persist(
                in: managedObjectContext,
                context: Persistence.Twitter.PersistContextV2(
                    dictionary: dictionary,
                    me: me,
                    networkDate: response.networkDate
                )
            )
            
            // amend the v2 missing properties
            if let lookupResponse = _lookupResponse, let me = me {
                lookupResponse.update(statuses: statusArray, me: me)
            }
        }   // end try await managedObjectContext.performChanges
        
        return response
    }
    
    public func twitterUserTimelineV1(
        query: Twitter.API.Statuses.Timeline.TimelineQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let response = try await Twitter.API.Statuses.Timeline.user(
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
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist TwitterStatus
            for entity in response.value {
                let persistContext = Persistence.TwitterStatus.PersistContext(
                    entity: entity,
                    me: me,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let _ = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
            }
        }
        
        return response
    }
    
}

extension APIService {
    
    public func mastodonUserTimeline(
        accountID: Mastodon.Entity.Account.ID,
        query: Mastodon.API.Account.AccountStatusesQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Account.statuses(
            session: session,
            domain: authenticationContext.domain,
            accountID: accountID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            // log rate limit
            // response.logRateLimit()
            
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let user = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist status
            for entity in response.value {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: user,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
                
                let _ = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
            }
        }
        
        return response
    }
}
