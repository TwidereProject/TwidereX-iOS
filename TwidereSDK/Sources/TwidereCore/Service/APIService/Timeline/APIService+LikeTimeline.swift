//
//  APIService+LikeTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-18.
//  Copyright © 2021 Twidere. All rights reserved.
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
    public func twitterLikeTimeline(
        query: Twitter.API.Statuses.Timeline.TimelineQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let response = try await Twitter.API.Favorites.list(
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
            // persist status
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
    public func mastodonLikeTimeline(
        query: Mastodon.API.Favorite.FavoriteStatusesQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Favorite.statuses(
            session: session,
            domain: authenticationContext.domain,
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
