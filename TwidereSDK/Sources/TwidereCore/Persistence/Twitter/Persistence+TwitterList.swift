//
//  TwitterList.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterList {
    
    public struct PersistContext {
        public let entity: Entity
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Entity,
            networkDate: Date
        ) {
            self.entity = entity
            self.networkDate = networkDate
        }
        
        public struct Entity {
            public let list: Twitter.Entity.V2.List
            public let owner: Twitter.Entity.V2.User
            
            public init(
                list: Twitter.Entity.V2.List,
                owner: Twitter.Entity.V2.User
            ) {
                self.list = list
                self.owner = owner
            }
        }
    }
    
    public struct PersistResult {
        public let list: TwitterList
        public let isNewInsertion: Bool
        public let isNewInsertionOwner: Bool
        
        public init(
            list: TwitterList,
            isNewInsertion: Bool,
            isNewInsertionOwner: Bool
        ) {
            self.list = list
            self.isNewInsertion = isNewInsertion
            self.isNewInsertionOwner = isNewInsertionOwner
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(object: old, context: context)
            return PersistResult(list: old, isNewInsertion: false, isNewInsertionOwner: false)
        } else {
            let result = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContextV2(
                    entity: context.entity.owner,
                    me: nil,
                    cache: nil,
                    networkDate: context.networkDate
                )
            )
            let relationship = TwitterList.Relationship(owner: result.user)
            let new = create(in: managedObjectContext, context: context, relationship: relationship)
            return PersistResult(list: new, isNewInsertion: true, isNewInsertionOwner: result.isNewInsertion)
        }
    }
    
}

extension Persistence.TwitterList {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterList? {
        let request = TwitterList.sortedFetchRequest
        request.predicate = TwitterList.predicate(id: context.entity.list.id)
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
        relationship: TwitterList.Relationship
    ) -> TwitterList {
        let property = TwitterList.Property(
            entity: context.entity.list,
            networkDate: context.networkDate
        )
        let object = TwitterList.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(object: object, context: context)
        return object
    }
    
    public static func merge(
        object: TwitterList,
        context: PersistContext
    ) {
        guard context.networkDate > object.updatedAt else { return }
        let property = TwitterList.Property(
            entity: context.entity.list,
            networkDate: context.networkDate
        )
        object.update(property: property)
        update(object: object, context: context)
    }
    
    private static func update(
        object: TwitterList,
        context: PersistContext
    ) {
        let entity = context.entity.list
        
        entity.private.flatMap { object.update(private: $0) }
        entity.memberCount.flatMap { object.update(memberCount: Int64($0)) }
        entity.followerCount.flatMap { object.update(followerCount: Int64($0)) }
        entity.description.flatMap { object.update(theDescription: $0) }
        entity.createdAt.flatMap { object.update(createdAt: $0) }
    }
    
}
