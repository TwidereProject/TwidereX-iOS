//
//  Persistence+TwitterUser+V2.swift
//  Persistence+TwitterUser+V2
//
//  Created by Cirno MainasuK on 2021-8-31.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import CoreData
import CoreDataStack
import Foundation
import TwitterSDK

extension Persistence.TwitterUser {
    
    public struct PersistContextV2 {
        public let entity: Twitter.Entity.V2.User
        public let me: TwitterUser?
        public let cache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
    }
    
    public struct PersistResultV2 {
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
        context: PersistContextV2
    ) -> PersistResultV2 {
        if let oldTwitterUser = fetch(in: managedObjectContext, context: context) {
            merge(twitterUser: oldTwitterUser, context: context)
            return PersistResultV2(user: oldTwitterUser, isNewInsertion: false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return PersistResultV2(user: user, isNewInsertion: true)
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
        user.update(bioEntitiesTransient: TwitterEntity(entity: context.entity.entities?.description))
        user.update(urlEntitiesTransient: TwitterEntity(entity: context.entity.entities?.url))
        
        if let publicMetrics = context.entity.publicMetrics {
            if let tweetCount = publicMetrics.tweetCount {
                user.update(statusesCount: Int64(tweetCount))
            }
            if let followingCount = publicMetrics.followingCount {
                user.update(followingCount: Int64(followingCount))
            }
            if let followersCount = publicMetrics.followersCount {
                user.update(followersCount: Int64(followersCount))
            }
            if let listedCount = publicMetrics.listedCount {
                user.update(listedCount: Int64(listedCount))
            }            
        }

        // convertible properties
        if let profileBannerURL = context.entity.profileBannerURL {
            user.update(profileBannerURL: profileBannerURL)
        }
        
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
