//
//  Persistence+TwitterUser+V2.swift
//  Persistence+TwitterUser+V2
//
//  Created by Cirno MainasuK on 2021-8-31.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterUser {
    
    struct PersistContextV2 {
        let entity: Twitter.Entity.V2.User
        let cache: Persistence.PersistCache<TwitterUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) -> (TwitterUser, Bool) {
        if let oldTwitterUser = fetch(in: managedObjectContext, context: context) {
            merge(twitterUser: oldTwitterUser, context: context)
            return (oldTwitterUser, false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return (user, true)
        }
    }
    
}

extension Persistence.TwitterUser {
    
    static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) -> TwitterUser? {
        if let cache = context.cache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = TwitterUser.sortedFetchRequest
            request.predicate = TwitterUser.predicate(id: context.entity.id)
            request.fetchLimit = 1
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
    }
    
    @discardableResult
    static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) -> TwitterUser {
        let property = TwitterUser.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        let user = TwitterUser.insert(into: managedObjectContext, property: property)
        update(twitterUser: user, context: context)
        return user
    }
    
    static func merge(
        twitterUser user: TwitterUser,
        context: PersistContextV2
    ) {
        guard context.networkDate > user.updatedAt else { return }
        let property = TwitterUser.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        user.update(property: property)
        update(twitterUser: user, context: context)
    }
    
    private static func update(
        twitterUser user: TwitterUser,
        context: PersistContextV2
    ) {
//        user.update(bioEntities: TwitterEntity(entity: context.entity.entities?.description))
//        user.update(urlEntities: TwitterEntity(entity: context.entity.entities?.url))
        
        if let count = context.entity.publicMetrics?.tweetCount {
            user.update(statusesCount: Int64(count))
        }
        if let count = context.entity.publicMetrics?.followingCount {
            user.update(followingCount: Int64(count))
        }
        if let count = context.entity.publicMetrics?.followersCount {
            user.update(followersCount: Int64(count))
        }
        if let count = context.entity.publicMetrics?.listedCount {
            user.update(listedCount: Int64(count))
        }
    }
    
}
