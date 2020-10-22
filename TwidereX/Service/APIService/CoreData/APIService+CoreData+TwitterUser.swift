//
//  APIService+CoreData+TwitterUser.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    static func createOrMergeTwitterUser(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        entity: Twitter.Entity.User,
        networkDate: Date,
        log: OSLog
    ) -> (user: TwitterUser, isCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        }
        
        // fetch old twitter user
        let oldTwitterUser: TwitterUser? = {
            let request = TwitterUser.sortedFetchRequest
            request.predicate = TwitterUser.predicate(idStr: entity.idStr)
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldTwitterUser = oldTwitterUser {
            // merge old twitter usre
            APIService.mergeTwitterUser(for: requestTwitterUser, old: oldTwitterUser, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "find old twitter user %{public}s: name %s", entity.idStr, oldTwitterUser.name)
            return (oldTwitterUser, false)
        } else {
            let metricsProperty = TwitterUserMetrics.Property(followersCount: entity.followersCount, followingCount: entity.friendsCount, listedCount: entity.listedCount, tweetCount: entity.statusesCount)
            let metrics = TwitterUserMetrics.insert(into: managedObjectContext, property: metricsProperty)
            
            let twitterUserProperty = TwitterUser.Property(entity: entity, networkDate: networkDate)
            let twitterUser = TwitterUser.insert(
                into: managedObjectContext,
                property: twitterUserProperty,
                metrics: metrics,
                following: (entity.following ?? false) ? requestTwitterUser : nil,
                followRequestSent: (entity.followRequestSent ?? false) ? requestTwitterUser : nil
            )
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.identifier.uuidString, twitterUserProperty.name)
            return (twitterUser, true)
        }
    }
    
    static func mergeTwitterUser(for requestTwitterUser: TwitterUser?, old user: TwitterUser, entity: Twitter.Entity.User, networkDate: Date) {
        guard networkDate > user.updatedAt else { return }
        // only fulfill API supported fields
        user.update(name: entity.name)
        user.update(username: entity.screenName)
        entity.userDescription.flatMap { user.update(bioDescription: $0) }
        entity.url.flatMap { user.update(url: $0) }
        entity.location.flatMap { user.update(location: $0) }
        entity.protected.flatMap { user.update(protected: $0) }
        entity.profileBannerURL.flatMap { user.update(profileBannerURL: $0) }
        entity.profileImageURLHTTPS.flatMap { user.update(profileImageURL: $0) }
        
        user.setupMetricsIfNeeds()
        entity.friendsCount.flatMap { user.metrics?.update(followingCount: $0) }
        entity.followersCount.flatMap { user.metrics?.update(followersCount: $0) }
        entity.listedCount.flatMap { user.metrics?.update(listedCount: $0) }
        entity.statusesCount.flatMap { user.metrics?.update(tweetCount: $0) }
        
        // relationship with requestTwitterUser
        if let requestTwitterUser = requestTwitterUser {
            entity.following.flatMap { user.update(following: $0, twitterUser: requestTwitterUser) }
            entity.followRequestSent.flatMap { user.update(followRequestSent: $0, twitterUser: requestTwitterUser) }
        }
        // TODO: merge more fileds
        
        user.didUpdate(at: networkDate)
    }
    
}