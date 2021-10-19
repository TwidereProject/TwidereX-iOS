//
//  APIService+HomeTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import TwitterSDK
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    static let homeTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    func twitterHomeTimeline(
        maxID: Twitter.Entity.Tweet.ID? = nil,
        count: Int = 100,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let query = Twitter.API.Statuses.TimelineQuery(count: count, maxID: maxID)
        
        let response = try await Twitter.API.Statuses.home(
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
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.twitterUser
            // persist TwitterStatus
            var statusArray: [TwitterStatus] = []
            for entity in response.value {
                let persistContext = Persistence.TwitterStatus.PersistContext(
                    entity: entity,
                    me: me,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let (status, _) = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                statusArray.append(status)
            }
            
            // locate anchor status
            let anchorStatus: TwitterStatus? = {
                guard let maxID = maxID else { return nil }
                let request = TwitterStatus.sortedFetchRequest
                request.predicate = TwitterStatus.predicate(id: maxID)
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            // update hasMore flag for anchor status
            let acct = Feed.Acct.twitter(userID: authenticationContext.userID)
            if let anchorStatus = anchorStatus,
               let feed = anchorStatus.feed(kind: .home, acct: acct) {
                feed.update(hasMore: false)
            }
        
            // persist Feed relationship
            let sortedStatuses = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
            let oldestStatus = sortedStatuses.first
            for status in sortedStatuses {
                let _feed = status.feed(kind: .home, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: .home,
                        hasMore: false,
                        createdAt: status.createdAt,
                        updatedAt: response.networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    status.attach(feed: feed)
                    
                    // set hasMore on oldest status if is new feed
                    if status === oldestStatus {
                        feed.update(hasMore: true)
                    }
                }
            }
        }
        
        return response
    }
    
}

extension APIService {
    func mastodonHomeTimeline(
        maxID: Mastodon.Entity.Status.ID? = nil,
        count: Int = 100,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let query = Mastodon.API.Timeline.TimelineQuery(
            local: nil,
            remote: nil,
            onlyMedia: nil,
            maxID: maxID,
            sinceID: nil,
            minID: nil,
            limit: count
        )
        
        let response = try await Mastodon.API.Timeline.home(
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
            let user = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.mastodonUser
            
            // persist MastodonStatus
            var statusArray: [MastodonStatus] = []
            for entity in response.value {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    user: user,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                
                let (status, _) = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                statusArray.append(status)
            }
            
            // locate anchor status
            let anchorStatus: MastodonStatus? = {
                guard let maxID = maxID else { return nil }
                let request = MastodonStatus.sortedFetchRequest
                request.predicate = MastodonStatus.predicate(domain: authenticationContext.domain, id: maxID)
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            // update hasMore flag for anchor status
            let acct = Feed.Acct.mastodon(domain: authenticationContext.domain, userID: authenticationContext.userID)
            if let anchorStatus = anchorStatus,
               let feed = anchorStatus.feed(kind: .home, acct: acct) {
                feed.update(hasMore: false)
            }
            
            // persist Feed relationship
            let sortedStatuses = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
            let oldestStatus = sortedStatuses.first
            for status in sortedStatuses {
                let _feed = status.feed(kind: .home, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: .home,
                        hasMore: false,
                        createdAt: status.createdAt,
                        updatedAt: response.networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    status.attach(feed: feed)
                    
                    // set hasMore on oldest status if is new feed
                    if status === oldestStatus {
                        feed.update(hasMore: true)
                    }
                }
            }
        }

        return response
    }
}
