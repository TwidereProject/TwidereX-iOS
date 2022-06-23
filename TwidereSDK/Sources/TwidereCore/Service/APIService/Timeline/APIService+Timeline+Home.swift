//
//  APIService+Timeline+Home.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
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
    
    static let homeTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    public func twitterHomeTimeline(
        query: Twitter.API.V2.User.Timeline.HomeQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Timeline.HomeContent> {
        let response = try await Twitter.API.V2.User.Timeline.home(
            session: session,
            userID: authenticationContext.userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        var lookupResponse = TwitterBatchLookupResponse()
        
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
        lookupResponse.merge(_lookupResponse)
        
        
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
            
            // locate anchor status
            let anchorStatus: TwitterStatus? = {
                guard let untilID = query.untilID else { return nil }
                let request = TwitterStatus.sortedFetchRequest
                request.predicate = TwitterStatus.predicate(id: untilID)
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
            let feedStatusIDs = (response.value.data ?? []).map { $0.id }
            let sortedStatuses = statusArray
                .filter { feedStatusIDs.contains($0.id) }
                .sorted(by: { $0.createdAt < $1.createdAt })
                .removingDuplicates()
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
        }   // end managedObjectContext.performChanges
        

        
        return response
    }

    
    public func twitterHomeTimelineV1(
        maxID: Twitter.Entity.Tweet.ID? = nil,
        count: Int = 100,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let query = Twitter.API.Statuses.Timeline.TimelineQuery(count: count, maxID: maxID)
        
        let response = try await Twitter.API.Statuses.Timeline.home(
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
            var statusArray: [TwitterStatus] = []
            for entity in response.value {
                let persistContext = Persistence.TwitterStatus.PersistContext(
                    entity: entity,
                    me: me,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let result = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                statusArray.append(result.status)
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
    public func mastodonHomeTimeline(
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
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            // persist MastodonStatus
            var statusArray: [MastodonStatus] = []
            for entity in response.value {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: me,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                
                let result = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                let status = result.status
                statusArray.append(status)
                
                #if DEBUG
                result.log()
                #endif
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
            
            // persist relationship
            let sortedStatuses = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
            let oldestStatus = sortedStatuses.first
            for status in sortedStatuses {
                // set friendship
                if let me = me {
                    status.author.update(isFollow: true, by: me)
                }
                
                // attach to Feed
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
