//
//  Persistence+MastodonUser.swift
//  Persistence+MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonUser {
    
    struct PersistContext {
        let domain: String
        let entity: Mastodon.Entity.Account
        let cache: Persistence.PersistCache<MastodonUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    struct PersistResult {
        let user: MastodonUser
        let isNewInsertion: Bool
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let oldMastodonUser = fetch(in: managedObjectContext, context: context) {
            merge(mastodonUser: oldMastodonUser, context: context)
            return PersistResult(user: oldMastodonUser, isNewInsertion: false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return PersistResult(user: user, isNewInsertion: true)
        }
    }
    
}

extension Persistence.MastodonUser {
    
    static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonUser? {
        if let cache = context.cache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = MastodonUser.sortedFetchRequest
            request.predicate = MastodonUser.predicate(
                domain: context.domain,
                id: context.entity.id
            )
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
    ) -> MastodonUser {
        let property = MastodonUser.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let user = MastodonUser.insert(into: managedObjectContext, property: property)
        return user
    }
    
    static func merge(
        mastodonUser user: MastodonUser,
        context: PersistContext
    ) {
        guard context.networkDate > user.updatedAt else { return }
        let property = MastodonUser.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        user.update(property: property)
    }
    
    private static func update(
        mastodonUser user: MastodonUser,
        context: PersistContext
    ) {
        // TODO:
    }   // end func update

}

extension Persistence.MastodonUser {
    struct RelationshipContext {
        let entity: Mastodon.Entity.Relationship
        let me: MastodonUser
        let networkDate: Date
        let log = OSLog.api
    }

    static func update(
        mastodonUser user: MastodonUser,
        context: RelationshipContext
    ) {
        guard context.entity.id != context.me.id else { return }    // not update relationship for self

        let relationship = context.entity
        let me = context.me
        
        user.update(isFollow: relationship.following, by: me)
        relationship.requested.flatMap { user.update(isFollowRequestSent: $0, from: me) }
        // relationship.endorsed.flatMap { user.update(isEndorsed: $0, by: me) }
        me.update(isFollow: relationship.followedBy, by: user)
        relationship.muting.flatMap { user.update(isMute: $0, by: me) }
        user.update(isBlock: relationship.blocking, by: me)
        // relationship.domainBlocking.flatMap { user.update(isDomainBlocking: $0, by: me) }
        relationship.blockedBy.flatMap { me.update(isBlock: $0, by: user) }
    }
}
