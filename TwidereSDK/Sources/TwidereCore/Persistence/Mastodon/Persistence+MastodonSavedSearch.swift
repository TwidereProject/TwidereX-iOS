//
//  Persistence+MastodonSavedSearch.swift
//  
//
//  Created by MainasuK on 2022-1-6.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.MastodonSavedSearch {
    
    public struct PersistContext {
        public let entity: String
        public let me: MastodonUser
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: String,
            me: MastodonUser,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let savedSearch: MastodonSavedSearch
        public let isNewInsertion: Bool
        
        public init(
            savedSearch: MastodonSavedSearch,
            isNewInsertion: Bool
        ) {
            self.savedSearch = savedSearch
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(object: old, context: context)
            return PersistResult(
                savedSearch: old,
                isNewInsertion: false
            )
        } else {
            let object = create(
                in: managedObjectContext,
                context: context,
                relationship: MastodonSavedSearch.Relationship(user: context.me)
            )
            return PersistResult(
                savedSearch: object,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.MastodonSavedSearch {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonSavedSearch? {
        do {
            let request = MastodonSavedSearch.sortedFetchRequest
            request.predicate = MastodonSavedSearch.predicate(
                userID: context.me.id,
                domain: context.me.domain,
                query: context.entity
            )
            request.fetchLimit = 1
            return try managedObjectContext.fetch(request).first
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext,
        relationship: MastodonSavedSearch.Relationship
    ) -> MastodonSavedSearch {
        let property = MastodonSavedSearch.Property(
            query: context.entity,
            createdAt: context.networkDate
        )
        let object = MastodonSavedSearch.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(object: object, context: context)
        return object
    }
    
    public static func merge(
        object: MastodonSavedSearch,
        context: PersistContext
    ) {
        let property = MastodonSavedSearch.Property(
            query: context.entity,
            createdAt: context.networkDate
        )
        object.update(property: property)
        update(object: object, context: context)
    }
    
    private static func update(
        object: MastodonSavedSearch,
        context: PersistContext
    ) {
        // do nothing
    }
    
}
