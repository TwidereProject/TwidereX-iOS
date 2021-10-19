//
//  Persistence+TwitterUser.swift
//  Persistence+TwitterUser
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterUser {
    
    struct PersistContext {
        let entity: Twitter.Entity.User
        let me: TwitterUser?
        let cache: Persistence.PersistCache<TwitterUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
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
        context: PersistContext
    ) -> TwitterUser? {
        if let cache = context.cache {
            return cache.dictionary[context.entity.idStr]
        } else {
            let request = TwitterUser.sortedFetchRequest
            request.predicate = TwitterUser.predicate(id: context.entity.idStr)
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
        context: PersistContext
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
        context: PersistContext
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
        context: PersistContext
    ) {
        user.update(name: context.entity.name)
        user.update(username: context.entity.screenName)
        
        user.update(bio: context.entity.userDescription)
        user.update(bioEntities: TwitterEntity(entity: context.entity.entities?.description))
        user.update(createdAt: context.entity.createdAt)
        user.update(location: context.entity.location)
        user.update(profileBannerURL: context.entity.profileBannerURL)
        user.update(profileImageURL: context.entity.profileImageURLHTTPS)
        user.update(protected: context.entity.protected ?? false)
        user.update(url: context.entity.url)
        user.update(urlEntities: TwitterEntity(entity: context.entity.entities?.url))
        user.update(verified: context.entity.verified ?? false)
        
        if let count = context.entity.statusesCount {
            user.update(statusesCount: Int64(count))
        }
        if let count = context.entity.friendsCount {
            user.update(followingCount: Int64(count))
        }
        if let count = context.entity.followersCount {
            user.update(followersCount: Int64(count))
        }
        if let count = context.entity.listedCount {
            user.update(listedCount: Int64(count))
        }
        
        // relationship
        if let me = context.me {
            if let following = context.entity.following {
                user.update(isFollow: following, by: me)
            }
            if let followRequestSent = context.entity.followRequestSent {
                user.update(isFollowRequestSent: followRequestSent, from: me)
            }
        }
    }   // end func update
    
}