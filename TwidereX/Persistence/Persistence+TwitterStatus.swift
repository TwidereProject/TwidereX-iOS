//
//  Persistence+TwitterStatus.swift
//  Persistence+TwitterStatus
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterStatus {
    
    struct PersistContext {
        let entity: Twitter.Entity.Tweet
        let statusCache: APIService.Persist.PersistCache<TwitterStatus>?
        let userCache: APIService.Persist.PersistCache<TwitterUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> (TwitterStatus, Bool) {
        
        let repost = context.entity.retweetedStatus.flatMap { entity -> TwitterStatus in
            let (status, _) = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    entity: entity,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return status
        }
        
        let quote = context.entity.quotedStatus.flatMap { entity -> TwitterStatus in
            let (status, _) = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    entity: entity,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return status
        }
        
        if let oldStatus = fetch(in: managedObjectContext, context: context) {
            merge(twitterStatus: oldStatus, context: context)
            return (oldStatus, false)
        } else {
            let (author, _) = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContext(
                    entity: context.entity.user,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            
            let relationship = TwitterStatus.Relationship(
                author: author,
                repost: repost,
                quote: quote
            )
            let status = create(in: managedObjectContext, context: context, relationship: relationship)
            return (status, true)
        }
    }
    
}

extension Persistence.TwitterStatus {
    
    static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterStatus? {
        if let cache = context.statusCache {
            return cache.dictionary[context.entity.idStr]
        } else {
            let request = TwitterStatus.sortedFetchRequest
            request.predicate = TwitterStatus.predicate(id: context.entity.idStr)
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
        relationship: TwitterStatus.Relationship
    ) -> TwitterStatus {
        let property = TwitterStatus.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        let status = TwitterStatus.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        return status
    }
    
    static func merge(twitterStatus status: TwitterStatus, context: PersistContext) {
        guard context.networkDate > status.updatedAt else { return }
        let property = TwitterStatus.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        status.update(property: property)
    }
    
}


//extension Persistence.TwitterStatus {
//
//    private static func batchInsertRequest(context: PersistContext) -> NSBatchInsertRequest {
//        var index = 0
//        let count = context.entities.count
//
//        let request = NSBatchInsertRequest(
//            entity: TwitterStatus.entity()
//        ) { (object: NSManagedObject) -> Bool in
//            guard index < count else { return true }
//            if let status = object as? TwitterStatus {
//                let property = TwitterStatus.Property(
//                    entity: context.entities[index],
//                    networkDate: context.networkDate
//                )
//                status.configure(property: property)
//            }
//            index += 1
//            return false
//        }
//
//        return request
//    }
//
//}

extension Persistence.TwitterStatus {
    static func setupDictionary(
        entities: [Twitter.Entity.Tweet],
        dictionary: inout [Twitter.Entity.Tweet.ID: Twitter.Entity.Tweet]
    ) {
        for entity in entities {
            setupDictionary(entity: entity, dictionary: &dictionary)
        }
    }
    
    static func setupDictionary(
        entity: Twitter.Entity.Tweet,
        dictionary: inout [Twitter.Entity.Tweet.ID: Twitter.Entity.Tweet]
    ) {
        dictionary[entity.idStr] = entity
        if let retweet = entity.retweetedStatus {
            setupDictionary(entity: retweet, dictionary: &dictionary)
        }
        if let quote = entity.quotedStatus {
            setupDictionary(entity: quote, dictionary: &dictionary)
        }
    }
}
