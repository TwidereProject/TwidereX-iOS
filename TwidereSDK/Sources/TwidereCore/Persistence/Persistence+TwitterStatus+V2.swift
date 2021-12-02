//
//  Persistence+TwitterStatus+V2.swift
//  Persistence+TwitterStatus+V2
//
//  Created by Cirno MainasuK on 2021-8-31.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterStatus {

    public struct PersistContextV2 {
        public let entity: Entity
        public let repost: Entity?     // status.repost
        public let quote: Entity?
        public let replyTo: Entity?
        
        public let dictionary: Twitter.Response.V2.DictContent
        
        public let user: TwitterUser?
        public let statusCache: Persistence.PersistCache<TwitterStatus>?
        public let userCache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Persistence.TwitterStatus.PersistContextV2.Entity,
            repost: Persistence.TwitterStatus.PersistContextV2.Entity?,
            quote: Persistence.TwitterStatus.PersistContextV2.Entity?,
            replyTo: Persistence.TwitterStatus.PersistContextV2.Entity?,
            dictionary: Twitter.Response.V2.DictContent,
            user: TwitterUser?,
            statusCache: Persistence.PersistCache<TwitterStatus>?,
            userCache: Persistence.PersistCache<TwitterUser>?,
            networkDate: Date
        ) {
            self.entity = entity
            self.repost = repost
            self.quote = quote
            self.replyTo = replyTo
            self.dictionary = dictionary
            self.user = user
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
        
        public struct Entity {
            public init(
                status: Twitter.Entity.V2.Tweet,
                author: Twitter.Entity.V2.User
            ) {
                self.status = status
                self.author = author
            }
            
            public let status: Twitter.Entity.V2.Tweet
            public let author: Twitter.Entity.V2.User
        }
        
        public func entity(statusID: Twitter.Entity.V2.Tweet.ID) -> Entity? {
            guard let status = dictionary.tweetDict[statusID],
                  let authorID = status.authorID,
                  let user = dictionary.userDict[authorID]
            else { return nil }
            return Entity(
                status: status,
                author: user
            )
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) -> (TwitterStatus, Bool) {
                
        // build tree
        // TODO: in reply to
        // let replyTo = context.replyTo.flatMap { entity in … }
        
        let repost = context.repost.flatMap { entity -> TwitterStatus in
            let (status, _) = createOrMerge(
                in: managedObjectContext,
                context: PersistContextV2(
                    entity: entity,
                    repost: nil,
                    quote: context.quote,
                    replyTo: nil,
                    dictionary: context.dictionary,
                    user: context.user,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return status
        }
        
        let quote: TwitterStatus? = {
            guard repost == nil else { return nil }
            return context.quote.flatMap { entity -> TwitterStatus in
                let (status, _) = createOrMerge(
                    in: managedObjectContext,
                    context: PersistContextV2(
                        entity: entity,
                        repost: nil,
                        quote: nil,
                        replyTo: nil,
                        dictionary: context.dictionary,
                        user: context.user,
                        statusCache: context.statusCache,
                        userCache: context.userCache,
                        networkDate: context.networkDate
                    )
                )
                return status
            }
        }()

        if let oldStatus = fetch(in: managedObjectContext, context: context) {
            merge(twitterStatus: oldStatus, context: context)
            return (oldStatus, false)
        } else {
            let (author, _) = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContextV2(
                    entity: context.entity.author,
                    me: context.user,
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
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) -> TwitterStatus? {
        if let cache = context.statusCache {
            return cache.dictionary[context.entity.status.id]
        } else {
            let request = TwitterStatus.sortedFetchRequest
            request.predicate = TwitterStatus.predicate(id: context.entity.status.id)
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
        context: PersistContextV2,
        relationship: TwitterStatus.Relationship
    ) -> TwitterStatus {
        let property = TwitterStatus.Property(
            status: context.entity.status,
            author: context.entity.author,
            place: nil,
            media: context.dictionary.media(for: context.entity.status) ?? [],
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
        context: PersistContextV2
    ) {
        guard context.networkDate > status.updatedAt else { return }

        let property = TwitterStatus.Property(
            status: context.entity.status,
            author: context.entity.author,
            place: nil,
            media: context.dictionary.media(for: context.entity.status) ?? [],
            networkDate: context.networkDate
        )
        status.update(property: property)
        update(twitterStatus: status, context: context)
        
        // merge user
        Persistence.TwitterUser.merge(
            twitterUser: status.author,
            context: Persistence.TwitterUser.PersistContextV2(
                entity: context.entity.author,
                me: context.user,
                cache: context.userCache,
                networkDate: context.networkDate
            )
        )
    }
    
    private static func update(
        twitterStatus status: TwitterStatus,
        context: PersistContextV2
    ) {
        status.update(entities: TwitterEntity(entity: context.entity.status.entities))
        
        context.entity.status.conversationID.flatMap { status.update(conversationID: $0) }
        context.dictionary.media(for: context.entity.status)
            .flatMap { media in
                let attachments = media.compactMap { $0.twitterAttachment }
                status.update(attachments: attachments)
            }
        context.dictionary.place(for: context.entity.status)
            .flatMap { place in
                status.update(location: place.twitterLocation)
            }
    }
    
}
