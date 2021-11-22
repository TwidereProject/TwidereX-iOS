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
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Status
        public let me: MastodonUser?
        public let statusCache: Persistence.PersistCache<MastodonStatus>?
        public let userCache: Persistence.PersistCache<MastodonUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            domain: String,
            entity: Mastodon.Entity.Status,
            me: MastodonUser?,
            statusCache: Persistence.PersistCache<MastodonStatus>?,
            userCache: Persistence.PersistCache<MastodonUser>?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let status: MastodonStatus
        public let isNewInsertion: Bool
        public let isNewInsertionAuthor: Bool
        
        public init(
            status: MastodonStatus,
            isNewInsertion: Bool,
            isNewInsertionAuthor: Bool
        ) {
            self.status = status
            self.isNewInsertion = isNewInsertion
            self.isNewInsertionAuthor = isNewInsertionAuthor
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.MastodonStatus.PersistResult", category: "Persist")
        public func log() {
            let statusInsertionFlag = isNewInsertion ? "+" : "-"
            let authorInsertionFlag = isNewInsertionAuthor ? "+" : "-"
            let contentPreview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(statusInsertionFlag)](\(status.id))[\(authorInsertionFlag)](\(status.author.id))@\(status.author.username): \(contentPreview)")
        }
        #endif
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        let repost = context.entity.reblog.flatMap { entity -> MastodonStatus in
            let result = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    domain: context.domain,
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
            merge(mastodonStatus: oldStatus, context: context)
            return PersistResult(
                status: oldStatus,
                isNewInsertion: false,
                isNewInsertionAuthor: false
            )
        } else {
            let authorResult = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: context.domain,
                    entity: context.entity.account,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            let author = authorResult.user
                
            let relationship = MastodonStatus.Relationship(
                author: author,
                repost: repost
            )
            let status = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )

            return PersistResult(
                status: status,
                isNewInsertion: true,
                isNewInsertionAuthor: authorResult.isNewInsertion
            )
        }
    }
    
}

extension Persistence.MastodonStatus {
    
    public static func fetch(
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
    public static func create(
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
    
    public static func merge(
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
        if let user = context.me {
            context.entity.reblogged.flatMap { status.update(isRepost: $0, by: user) }
            context.entity.favourited.flatMap { status.update(isLike: $0, by: user) }
        }
    }
    
}
