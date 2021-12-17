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
    
    public struct PersistContext {
        public let entity: Twitter.Entity.User
        public let me: TwitterUser?
        public let cache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.Entity.User,
            me: TwitterUser?,
            cache: Persistence.PersistCache<TwitterUser>?,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.cache = cache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let user: TwitterUser
        public let isNewInsertion: Bool
        
        public init(
            user: TwitterUser,
            isNewInsertion: Bool
        ) {
            self.user = user
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let oldTwitterUser = fetch(in: managedObjectContext, context: context) {
            merge(twitterUser: oldTwitterUser, context: context)
            return PersistResult(user: oldTwitterUser, isNewInsertion: false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return PersistResult(user: user, isNewInsertion: true)
        }
    }
    
}

extension Persistence.TwitterUser {

    public static func fetch(
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
    public static func create(
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
    
    public static func merge(
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
        user.update(profileBannerURL: context.entity.profileBannerURL)
        user.update(bioEntities: TwitterEntity(entity: context.entity.entities?.description))
        user.update(urlEntities: TwitterEntity(entity: context.entity.entities?.url))

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
