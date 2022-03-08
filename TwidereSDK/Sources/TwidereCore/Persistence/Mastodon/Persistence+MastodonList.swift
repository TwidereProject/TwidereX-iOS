//
//  Persistence+MastodonList.swift
//  
//
//  Created by MainasuK on 2022-3-8.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonList {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Entity
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            domain: String,
            entity: Entity,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.networkDate = networkDate
        }
        
        public struct Entity {
            public let list: Mastodon.Entity.List
            public let owner: MastodonUser
            
            public init(
                list: Mastodon.Entity.List,
                owner: MastodonUser
            ) {
                self.list = list
                self.owner = owner
            }
        }
    }
    
    public struct PersistResult {
        public let list: MastodonList
        public let isNewInsertion: Bool
        
        public init(
            list: MastodonList,
            isNewInsertion: Bool
        ) {
            self.list = list
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(object: old, context: context)
            return PersistResult(list: old, isNewInsertion: false)
        } else {
            let relationship = MastodonList.Relationship(owner: context.entity.owner)
            let new = create(in: managedObjectContext, context: context, relationship: relationship)
            return PersistResult(list: new, isNewInsertion: true)
        }
    }
    
}

extension Persistence.MastodonList {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonList? {
        let request = MastodonList.sortedFetchRequest
        request.predicate = MastodonList.predicate(
            domain: context.domain,
            id: context.entity.list.id
        )
        request.fetchLimit = 1
        do {
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
        relationship: MastodonList.Relationship
    ) -> MastodonList {
        let property = MastodonList.Property(
            entity: context.entity.list,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let object = MastodonList.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(object: object, context: context)
        return object
    }
    
    public static func merge(
        object: MastodonList,
        context: PersistContext
    ) {
        guard context.networkDate > object.updatedAt else { return }
        let property = MastodonList.Property(
            entity: context.entity.list,
            domain: context.domain,
            networkDate: context.networkDate
        )
        object.update(property: property)
        update(object: object, context: context)
    }
    
    private static func update(
        object: MastodonList,
        context: PersistContext
    ) {
        let entity = context.entity.list
        
        // TODO:
    }
    
}
