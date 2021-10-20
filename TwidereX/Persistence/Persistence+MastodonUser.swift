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
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> (MastodonUser, Bool) {
        if let oldMastodonUser = fetch(in: managedObjectContext, context: context) {
            merge(mastodonUser: oldMastodonUser, context: context)
            return (oldMastodonUser, false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return (user, true)
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
