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
    
    public struct PersistContext {
        public let entity: Twitter.Entity.Tweet
        public let me: TwitterUser?
        public let statusCache: Persistence.PersistCache<TwitterStatus>?
        public let userCache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.Entity.Tweet,
            me: TwitterUser?,
            statusCache: Persistence.PersistCache<TwitterStatus>?,
            userCache: Persistence.PersistCache<TwitterUser>?,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let status: TwitterStatus
        public let isNewInsertion: Bool
        public let isNewInsertionAuthor: Bool
        
        public init(
            status: TwitterStatus,
            isNewInsertion: Bool,
            isNewInsertionAuthor: Bool
        ) {
            self.status = status
            self.isNewInsertion = isNewInsertion
            self.isNewInsertionAuthor = isNewInsertionAuthor
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.TwitterStatus.PersistResult", category: "Persist")
        public func log() {
            let statusInsertionFlag = isNewInsertion ? "+" : "-"
            let authorInsertionFlag = isNewInsertionAuthor ? "+" : "-"
            let contentPreview = status.text.prefix(32).replacingOccurrences(of: "\n", with: " ")
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(statusInsertionFlag)](\(status.id))[\(authorInsertionFlag)](\(status.author.id))@\(status.author.username): \(contentPreview)")
        }
        #endif
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        let repost = context.entity.retweetedStatus.flatMap { entity -> TwitterStatus in
            let result = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    entity: entity,
                    me: context.me,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return result.status
        }
        
        let quote = context.entity.quotedStatus.flatMap { entity -> TwitterStatus in
            let result = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    entity: entity,
                    me: context.me,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return result.status
        }
        
        if let oldStatus = fetch(in: managedObjectContext, context: context) {
            merge(twitterStatus: oldStatus, context: context)
            return PersistResult(
                status: oldStatus,
                isNewInsertion: false,
                isNewInsertionAuthor: false
            )
        } else {
            let authorResult = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContext(
                    entity: context.entity.user,
                    me: context.me,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            let author = authorResult.user
            
            let relationship = TwitterStatus.Relationship(
                poll: nil,
                author: author,
                repost: repost,
                quote: quote
            )
            let status = create(in: managedObjectContext, context: context, relationship: relationship)
            return PersistResult(
                status: status,
                isNewInsertion: true,
                isNewInsertionAuthor: authorResult.isNewInsertion
            )
        }
    }
    
}

extension Persistence.TwitterStatus {
    
    public static func fetch(
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
    public static func create(
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
        update(twitterStatus: status, context: context)
        return status
    }
    
    public static func merge(
        twitterStatus status: TwitterStatus,
        context: PersistContext
    ) {
        guard context.networkDate > status.updatedAt else { return }
        
        let property = TwitterStatus.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        status.update(property: property)
        update(twitterStatus: status, context: context)
        
        // merge user
        Persistence.TwitterUser.merge(
            twitterUser: status.author,
            context: Persistence.TwitterUser.PersistContext(
                entity: context.entity.user,
                me: context.me,
                cache: context.userCache,
                networkDate: context.networkDate
            )
        )
    }
    
    private static func update(
        twitterStatus status: TwitterStatus,
        context: PersistContext
    ) {
        // prefer use V2 entities. only update entities when not exist
        if status.entities == nil {
            status.update(entities: TwitterEntity(
                entity: context.entity.entities,
                extendedEntity: context.entity.extendedEntities
            ))
        }
        
        context.entity.twitterAttachments.flatMap { status.update(attachments: $0) }
        context.entity.twitterLocation.flatMap { status.update(location:$0) }
        
        // update relationship
        if let me = context.me {
            context.entity.retweeted.flatMap { status.update(isRepost: $0, by: me) }
            context.entity.favorited.flatMap { status.update(isLike: $0, by: me) }
        }
    }
    
}

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
