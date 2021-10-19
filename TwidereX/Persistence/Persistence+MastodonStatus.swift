//
//  Persistence+MastodonStatus.swift
//  Persistence+MastodonStatus
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonStatus {
    
    struct PersistContext {
        let domain: String
        let entity: Mastodon.Entity.Status
        let user: MastodonUser?
        let statusCache: Persistence.PersistCache<MastodonStatus>?
        let userCache: Persistence.PersistCache<MastodonUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> (MastodonStatus, Bool) {
        
        let repost = context.entity.reblog.flatMap { entity -> MastodonStatus in
            let (status, _) = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    domain: context.domain,
                    entity: entity,
                    user: context.user,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return status
        }
        
        if let oldStatus = fetch(in: managedObjectContext, context: context) {
            merge(mastodonStatus: oldStatus, context: context)
            return (oldStatus, false)
        } else {
            let (author, _) = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: context.domain,
                    entity: context.entity.account,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
                
            let relationship = MastodonStatus.Relationship(
                author: author,
                repost: repost
            )
            let status = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )
            return (status, false)
        }
    }
    
}

extension Persistence.MastodonStatus {
    
    static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonStatus? {
        if let cache = context.statusCache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = MastodonStatus.sortedFetchRequest
            request.predicate = MastodonStatus.predicate(domain: context.domain, id: context.entity.id)
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
        context: PersistContext,
        relationship: MastodonStatus.Relationship
    ) -> MastodonStatus {
        let property = MastodonStatus.Property(
            domain: context.domain,
            entity: context.entity,
            networkDate: context.networkDate
        )
        let status = MastodonStatus.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(status: status, context: context)
        return status
    }
    
    static func merge(
        mastodonStatus status: MastodonStatus,
        context: PersistContext
    ) {
        guard context.networkDate > status.updatedAt else { return }
        let property = MastodonStatus.Property(
            domain: context.domain,
            entity: context.entity,
            networkDate: context.networkDate
        )
        status.update(property: property)
        update(status: status, context: context)
    }
    
    private static func update(
        status: MastodonStatus,
        context: PersistContext
    ) {
        // update relationship
        if let user = context.user {
            context.entity.reblogged.flatMap { status.update(isRepost: $0, by: user) }
            context.entity.favourited.flatMap { status.update(isLike: $0, by: user) }
        }
    }
    
}
