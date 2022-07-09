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
    public static var homeTimelineLoadNotification = Notification.Name("com.twidere.twiderex.APIService.homeTimelineLoadNotification")
}

extension APIService {

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

        let managedObjectContext = coreDataStack.newTaskContext()
        
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
                        
                        let userInfo: [AnyHashable: Any] = {
                            let feedCount = response.value.data?.count ?? 0
                            var userInfo: [AnyHashable: Any] = [
                                "count": feedCount,
                            ]
                            if let sinceID = query.sinceID {
                                userInfo["sinceID"] = sinceID
                            }
                            return userInfo
                        }()
                        NotificationCenter.default.post(name: APIService.homeTimelineLoadNotification, object: nil, userInfo: userInfo)
                        
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

            // persist
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
    }   // end func

    @available(*, deprecated, message: "")
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
    }   // end func
    
}

extension APIService {
    
    enum MastodonHomeTimelineTaskResult {
        case content(Mastodon.Response.Content<[Mastodon.Entity.Status]>)
        case persist([ManagedObjectRecord<MastodonStatus>])
    }
    
    public func mastodonHomeTimeline(
        query: Mastodon.API.Timeline.TimelineQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> [Mastodon.Response.Content<[Mastodon.Entity.Status]>] {
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch home timeline cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
                
        let managedObjectContext = coreDataStack.newTaskContext()

        let taskResults = try await withThrowingTaskGroup(of: MastodonHomeTimelineTaskResult.self) { group -> [MastodonHomeTimelineTaskResult] in
            group.addTask {
                let response = try await Mastodon.API.Timeline.home(
                    session: self.session,
                    domain: authenticationContext.domain,
                    query: query,
                    authorization: authenticationContext.authorization
                )
                #if DEBUG
                response.logRateLimit(category: "HomeContent")
                #endif
                return MastodonHomeTimelineTaskResult.content(response)
            }
            
            var results: [MastodonHomeTimelineTaskResult] = []
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
                        let records: [ManagedObjectRecord<MastodonStatus>] = await managedObjectContext.perform(schedule: .enqueued) {
                            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
                            var records: [ManagedObjectRecord<MastodonStatus>] = []
                            for entity in response.value {
                                let result = Persistence.MastodonStatus.createOrMerge(
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
                                records.append(.init(objectID: result.status.objectID))
                            }
                            return records
                        }

                        let userInfo: [AnyHashable: Any] = {
                            let feedCount = response.value.count
                            var userInfo: [AnyHashable: Any] = [
                                "count": feedCount,
                            ]
                            if let sinceID = query.sinceID {
                                userInfo["sinceID"] = sinceID
                            }
                            return userInfo
                        }()
                        NotificationCenter.default.post(name: APIService.homeTimelineLoadNotification, object: nil, userInfo: userInfo)

                        return MastodonHomeTimelineTaskResult.persist(records)
                    }
                    // fetch next page
                     
                    if let sinceID = query.sinceID, let maxID = response.link?.maxID {
                        group.addTask {
                            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch home: \(maxID)")
                            let response = try await Mastodon.API.Timeline.home(
                                session: self.session,
                                domain: authenticationContext.domain,
                                query: .init(
                                    local: query.local,
                                    remote: query.remote,
                                    onlyMedia: query.onlyMedia,
                                    maxID: maxID,
                                    sinceID: sinceID,
                                    minID: nil,
                                    limit: query.limit
                                ),
                                authorization: authenticationContext.authorization
                            )
                            #if DEBUG
                            response.logRateLimit(category: "HomeContent")
                            #endif
                            return MastodonHomeTimelineTaskResult.content(response)
                        }
                    }
                case .persist:
                    break
                }
            }
            return results
        }
        
        var contentResults: [Mastodon.Response.Content<[Mastodon.Entity.Status]>] = []
        var statusRecords: [ManagedObjectRecord<MastodonStatus>] = []
        
        for taskResult in taskResults {
            switch taskResult {
            case .content(let response):
                contentResults.append(response)
            case .persist(let records):
                statusRecords.append(contentsOf: records)
            }
        }
        
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user

            let statusArray = statusRecords.compactMap { $0.object(in: managedObjectContext) }
            assert(statusArray.count == statusRecords.count)

            // locate anchor status
            let anchorStatus: MastodonStatus? = {
                guard let maxID = query.maxID else { return nil }
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
            
            // persist
            let networkDate = contentResults.first?.networkDate ?? Date()
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
    }   // end func
    
}
