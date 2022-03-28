//
//  Persistence+TwitterSavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-24.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterSavedSearch {
    
    public struct PersistContext {
        public let entity: Twitter.Entity.SavedSearch
        public let me: TwitterUser
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.Entity.SavedSearch,
            me: TwitterUser,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let savedSearch: TwitterSavedSearch
        public let isNewInsertion: Bool
        
        public init(
            savedSearch: TwitterSavedSearch,
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
                relationship: TwitterSavedSearch.Relationship(user: context.me)
            )
            return PersistResult(
                savedSearch: object,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.TwitterSavedSearch {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterSavedSearch? {
        do {
            let request = TwitterSavedSearch.sortedFetchRequest
            request.predicate = TwitterSavedSearch.predicate(id: context.entity.idStr)
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
        relationship: TwitterSavedSearch.Relationship
    ) -> TwitterSavedSearch {
        let property = TwitterSavedSearch.Property(
            entity: context.entity
        )
        let object = TwitterSavedSearch.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(object: object, context: context)
        return object
    }
    
    public static func merge(
        object: TwitterSavedSearch,
        context: PersistContext
    ) {
        let property = TwitterSavedSearch.Property(
            entity: context.entity
        )
        object.update(property: property)
        update(object: object, context: context)
    }
    
    private static func update(
        object: TwitterSavedSearch,
        context: PersistContext
    ) {
        // do nothing
    }
    
}
