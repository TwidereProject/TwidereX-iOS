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
    
    public struct PersistContextV2 {
        public let entity: Twitter.Entity.V2.User
        public let user: TwitterUser?
        public let cache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
    }
    
    public static func createOrMerge(
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
    
    public static func fetch(
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
    public static func create(
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
    
    public static func merge(
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
        user.update(bioEntities: TwitterEntity(entity: context.entity.entities?.description))
        user.update(urlEntities: TwitterEntity(entity: context.entity.entities?.url))
        
        // V2 entity not contains relationship flags
    }
    
}

extension Persistence.TwitterUser {
    public struct RelationshipContext {
        public let entity: Twitter.API.V2.User.Follow.FollowContent
        public let me: TwitterUser
        public let isUnfollowAction: Bool
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.API.V2.User.Follow.FollowContent,
            me: TwitterUser,
            isUnfollowAction: Bool,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.isUnfollowAction = isUnfollowAction
            self.networkDate = networkDate
        }
    }
    
    public static func update(
        twitterUser user: TwitterUser,
        context: RelationshipContext
    ) {
        guard user.id != context.me.id else { return }
        
        let followContent = context.entity.data
        let me = context.me
        
        let following = followContent.following
        user.update(isFollow: following, by: me)
        if let pendingFollow = followContent.pendingFollow {
            user.update(isFollowRequestSent: pendingFollow, from: me)
        } else {
            user.update(isFollowRequestSent: false, from: me)
        }
        if !context.isUnfollowAction {
            // break blocking implicitly
            user.update(isBlock: false, by: me)
        }
    }
}
