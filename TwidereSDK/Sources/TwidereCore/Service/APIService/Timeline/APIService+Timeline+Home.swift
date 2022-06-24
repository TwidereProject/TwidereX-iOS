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

//class TwitterBatchLookupTask {
//
//    // input
//    let session: URLSession
//    let statusIDs: [Twitter.Entity.V2.Tweet.ID]
//
//    // output
//    let
//    init(
//        session: URLSession,
//        content: Twitter.API.V2.User.Timeline.HomeContent
//    ) {
//        var statusIDs: [Twitter.Entity.Tweet.ID] = []
//        statusIDs += (content.data ?? []).map { $0.id }
//        statusIDs += (content.includes?.tweets ?? []).map { $0.id }
//
//        self.session = session
//        self.statusIDs = statusIDs
//    }
//
//    func start() {
//        let chunks = stride(from: 0, to: statusIDs.count, by: 100).map {
//            statusIDs[$0..<Swift.min(statusIDs.count, $0 + 100)]
//        }
//
//        let _responses = await chunks.parallelMap { chunk -> Twitter.Response.Content<[Twitter.Entity.Tweet]>? in
//            let query = Twitter.API.Lookup.LookupQuery(ids: Array(chunk))
//            let response = try? await Twitter.API.Lookup.tweets(
//                session: self.session,
//                query: query,
//                authorization: authenticationContext.authorization
//            )
//            return response
//        }
//
//        let statuses = _responses
//            .compactMap { $0 }
//            .map { $0.value }
//            .flatMap { $0 }
//
//        return statuses
//    }
//
//
//}

extension APIService {
    
    static let homeTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    enum TwitterHomeTimelineTaskResult {
        case content(Twitter.Response.Content<Twitter.API.V2.User.Timeline.HomeContent>)
        case lookup([Twitter.Response.Content<[Twitter.Entity.Tweet]>])
        case persist([ManagedObjectRecord<TwitterStatus>])
    }
    
    public func twitterHomeTimeline(
        query: Twitter.API.V2.User.Timeline.HomeQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> [Twitter.Response.Content<Twitter.API.V2.User.Timeline.HomeContent>] {
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch home timeline cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif

        let managedObjectContext = backgroundManagedObjectContext
        
        // note: the coordinator not handle history merge for directly derived context
        // let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        // managedObjectContext.parent = self.backgroundManagedObjectContext
        // managedObjectContext.automaticallyMergesChangesFromParent = true
        
        let taskResults = try await withThrowingTaskGroup(of: TwitterHomeTimelineTaskResult.self) { group -> [TwitterHomeTimelineTaskResult] in
            group.addTask {
                let response = try await Twitter.API.V2.User.Timeline.home(
                    session: self.session,
                    userID: authenticationContext.userID,
                    query: query,
                    authorization: authenticationContext.authorization
                )
                #if DEBUG
                response.logRateLimit(category: "HomeContent")
                #endif
                return TwitterHomeTimelineTaskResult.content(response)
            }
            

            var results: [TwitterHomeTimelineTaskResult] = []
            while let next = try await group.next() {
                results.append(next)

                switch next {
                case .content(let response):
                    // persist response
                    group.addTask {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): persist home")
                        #if DEBUG
                        // log time cost
                        let start = CACurrentMediaTime()
                        defer {
                            let end = CACurrentMediaTime()
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
                        }
                        #endif
                        let records: [ManagedObjectRecord<TwitterStatus>] = await managedObjectContext.perform(schedule: .enqueued) {
                            let content = response.value
                            let dictionary = Twitter.Response.V2.DictContent(
                                tweets: [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                                users: content.includes?.users ?? [],
                                media: content.includes?.media ?? [],
                                places: content.includes?.places ?? [],
                                polls: content.includes?.polls ?? []
                            )
                            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
                            let statusArray = Persistence.Twitter.persist(
                                in: managedObjectContext,
                                context: Persistence.Twitter.PersistContextV2(
                                    dictionary: dictionary,
                                    me: me,
                                    networkDate: response.networkDate
                                )
                            )
                            return statusArray.map { ManagedObjectRecord<TwitterStatus>(objectID: $0.objectID) }
                        }
                        return TwitterHomeTimelineTaskResult.persist(records)
                    }
                    // fetch next page
                    if let sinceID = query.sinceID, let nextToken = response.value.meta.nextToken {
                        group.addTask {
                            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch home: \(nextToken)")
                            let response = try await Twitter.API.V2.User.Timeline.home(
                                session: self.session,
                                userID: authenticationContext.userID,
                                query: .init(
                                    sinceID: sinceID,
                                    untilID: nil,
                                    paginationToken: nextToken,
                                    maxResults: query.maxResults
                                ),
                                authorization: authenticationContext.authorization
                            )
                            #if DEBUG
                            response.logRateLimit(category: "HomeContent")
                            #endif
                            return TwitterHomeTimelineTaskResult.content(response)
                        }
                    }
                    // fetch lookup
                    group.addTask {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch lookup")
                        let responses = await self.twitterBatchLookupResponses(
                            content: response.value,
                            authenticationContext: authenticationContext
                        )
                        #if DEBUG
                        response.logRateLimit(category: "HomeLookup")
                        #endif
                        return TwitterHomeTimelineTaskResult.lookup(responses)
                    }
                case .lookup:
                    break
                case .persist:
                    break
                }
            }
            return results
        }
        
        var contentResults: [Twitter.Response.Content<Twitter.API.V2.User.Timeline.HomeContent>] = []
        var lookupResults: [Twitter.Response.Content<[Twitter.Entity.Tweet]>] = []
        var statusRecords: [ManagedObjectRecord<TwitterStatus>] = []
        
        for taskResult in taskResults {
            switch taskResult {
            case .content(let response):
                contentResults.append(response)
            case .lookup(let responses):
                lookupResults.append(contentsOf: responses)
            case .persist(let records):
                statusRecords.append(contentsOf: records)
            }
        }
        
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user

            let statusArray = statusRecords.compactMap { $0.object(in: managedObjectContext) }
            assert(statusArray.count == statusRecords.count)
            
            // amend the v2 missing properties
            if let me = me {
                var batchLookupResponse = TwitterBatchLookupResponse()
                for lookupResult in lookupResults {
                    for status in lookupResult.value {
                        batchLookupResponse.lookupDict[status.idStr] = status
                    }
                }
                batchLookupResponse.update(statuses: statusArray, me: me)
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
            let networkDate = contentResults.first?.networkDate ?? Date()
            let feedStatusIDs = contentResults
                .map { $0.value.data }
                .compactMap { $0 }
                .flatMap { $0 }
                .map { $0.id }
            let sortedStatuses = statusArray
                .filter { feedStatusIDs.contains($0.id) }
                .sorted(by: { $0.createdAt < $1.createdAt })
                .removingDuplicates()
            let oldestStatus = sortedStatuses.first
            for status in sortedStatuses {
                let _feed = status.feed(kind: .home, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: .home,
                        hasMore: false,
                        createdAt: status.createdAt,
                        updatedAt: networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    status.attach(feed: feed)

                    if status === oldestStatus, // set hasMore on oldest status if is new feed
                       query.sinceID == nil     // and break if is batch load mode
                    {
                        feed.update(hasMore: true)
                    }
                }
            }
        }   // end managedObjectContext.performChanges

        return contentResults
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
