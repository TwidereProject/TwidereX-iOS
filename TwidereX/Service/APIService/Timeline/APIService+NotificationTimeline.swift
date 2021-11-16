//
//  APIService+NotificationTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
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

    func twitterMentionTimeline(
        query: Twitter.API.Statuses.Timeline.TimelineQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let response = try await Twitter.API.Statuses.Timeline.mentions(
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
                    statusCache: nil,
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
                guard let maxID = query.maxID else { return nil }
                let request = TwitterStatus.sortedFetchRequest
                request.predicate = TwitterStatus.predicate(id: maxID)
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            
            // update hasMore flag for anchor status
            let acct = Feed.Acct.twitter(userID: authenticationContext.userID)
            if let anchorStatus = anchorStatus,
               let feed = anchorStatus.feed(kind: .notification, acct: acct) {
                feed.update(hasMore: false)
            }
            
            // persist Feed relationship
            let sortedStatuses = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
            let oldestStatus = sortedStatuses.first
            for status in sortedStatuses {
                let _feed = status.feed(kind: .notification, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: .notification,
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

    func mastodonNotificationTimeline(
        query: Mastodon.API.Notification.NotificationsQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> {
        let response = try await Mastodon.API.Notification.notifications(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            // persist notifications
            var statusArray: [MastodonNotification] = []
            for entity in response.value {
                let persistContext = Persistence.MastodonNotification.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: me,
                    notificationCache: nil,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let result = Persistence.MastodonNotification.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                statusArray.append(result.notification)
            }
            
            // locate anchor status
            let anchor: MastodonNotification? = {
                guard let maxID = query.maxID else { return nil }
                let request = MastodonNotification.sortedFetchRequest
                request.predicate = MastodonNotification.predicate(domain: authenticationContext.domain, id: maxID)
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            
            // update hasMore flag for anchor
            let acct = Feed.Acct.mastodon(domain: authenticationContext.domain, userID: authenticationContext.userID)
            if let anchor = anchor,
               let feed = anchor.feed(kind: .notification, acct: acct) {
                feed.update(hasMore: false)
            }
            
            // persist Feed relationship
            let sortedNotifications = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
            let oldestNotification = sortedNotifications.first
            for notification in sortedNotifications {
                let _feed = notification.feed(kind: .notification, acct: acct)
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kind: .notification,
                        hasMore: false,
                        createdAt: notification.createdAt,
                        updatedAt: response.networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    notification.attach(feed: feed)
                    
                    // set hasMore on oldest notification if is new feed
                    if notification === oldestNotification {
                        feed.update(hasMore: true)
                    }
                }
            }
        }   // end try await managedObjectContext.performChanges { … }
        
        return response
    }

}
