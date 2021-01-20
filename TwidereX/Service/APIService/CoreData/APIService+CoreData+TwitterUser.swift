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

extension APIService.CoreData {
    
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
            APIService.CoreData.mergeTwitterUser(for: requestTwitterUser, old: oldTwitterUser, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "find old twitter user %{public}s: name %s", entity.idStr, oldTwitterUser.name)
            return (oldTwitterUser, false)
        } else {
            let entities: TwitterUserEntities? = {
                let properties = entity.entities
                    .flatMap { TwitterUserEntitiesURL.Property.properties(from: $0, networkDate: networkDate) } ?? []
                let urls: [TwitterUserEntitiesURL] = properties.map { property in
                    TwitterUserEntitiesURL.insert(into: managedObjectContext, property: property)
                }
                guard !urls.isEmpty else { return nil }
                return TwitterUserEntities.insert(into: managedObjectContext, urls: urls)
            }()
            let metricsProperty = TwitterUserMetrics.Property(followersCount: entity.followersCount, followingCount: entity.friendsCount, listedCount: entity.listedCount, tweetCount: entity.statusesCount)
            let metrics = TwitterUserMetrics.insert(into: managedObjectContext, property: metricsProperty)
            
            let twitterUserProperty = TwitterUser.Property(entity: entity, networkDate: networkDate)
            let twitterUser = TwitterUser.insert(
                into: managedObjectContext,
                property: twitterUserProperty,
                entities: entities,
                metrics: metrics,
                followingBy: (entity.following ?? false) ? requestTwitterUser : nil,
                followRequestSentFrom: (entity.followRequestSent ?? false) ? requestTwitterUser : nil
            )
            
            // update tweet mentions
            let mentionsRequest = TweetEntitiesMention.sortedFetchRequest
            mentionsRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                TweetEntitiesMention.predicate(username: twitterUserProperty.username),
                TweetEntitiesMention.notHasUser()
            ])
            do {
                let mentsions = try managedObjectContext.fetch(mentionsRequest)
                mentsions.forEach { mention in mention.update(user: twitterUser) }
            } catch {
                assertionFailure(error.localizedDescription)
            }
            
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.identifier.uuidString, twitterUserProperty.name)
            return (twitterUser, true)
        }
    }
    
    static func mergeTwitterUser(for requestTwitterUser: TwitterUser?, old user: TwitterUser, entity: Twitter.Entity.User, networkDate: Date) {
        guard networkDate > user.updatedAt else { return }
        let property = TwitterUser.Property(entity: entity, networkDate: networkDate)
        
        // only fulfill API supported fields
        user.update(name: property.name)
        user.update(username: property.username)
        user.update(protected: property.protected)
        property.bioDescription.flatMap { user.update(bioDescription: $0) }
        property.url.flatMap { user.update(url: $0) }
        property.location.flatMap { user.update(location: $0) }
        property.profileBannerURL.flatMap { user.update(profileBannerURL: $0) }
        property.profileImageURL.flatMap { user.update(profileImageURL: $0) }
        
        // update entities
        user.setupEntitiesIfNeeds()
        let entitiesURLProperties = entity.entities
            .flatMap { TwitterUserEntitiesURL.Property.properties(from: $0, networkDate: networkDate) } ?? []
        user.update(entitiesURLProperties: entitiesURLProperties)
        
        user.setupMetricsIfNeeds()
        entity.friendsCount.flatMap { user.metrics?.update(followingCount: $0) }
        entity.followersCount.flatMap { user.metrics?.update(followersCount: $0) }
        entity.listedCount.flatMap { user.metrics?.update(listedCount: $0) }
        entity.statusesCount.flatMap { user.metrics?.update(tweetCount: $0) }
        
        // relationship with requestTwitterUser
        if let requestTwitterUser = requestTwitterUser {
            entity.following.flatMap { user.update(following: $0, by: requestTwitterUser) }
            entity.followRequestSent.flatMap { user.update(followRequestSent: $0, from: requestTwitterUser) }
        }

        // TODO: merge more fileds
        
        user.didUpdate(at: networkDate)
    }
    
}
