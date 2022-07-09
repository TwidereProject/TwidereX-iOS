//
//  Persistence+MastodonNotification.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonNotification {

    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Notification
        public let me: MastodonUser
        public let notificationCache: Persistence.PersistCache<MastodonNotification>?
        public let statusCache: Persistence.PersistCache<MastodonStatus>?
        public let userCache: Persistence.PersistCache<MastodonUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            domain: String,
            entity: Mastodon.Entity.Notification,
            me: MastodonUser,
            notificationCache: Persistence.PersistCache<MastodonNotification>?,
            statusCache: Persistence.PersistCache<MastodonStatus>?,
            userCache: Persistence.PersistCache<MastodonUser>?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.notificationCache = notificationCache
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let notification: MastodonNotification
        public let isNewInsertion: Bool
        public let isNewInsertionAccount: Bool
        public let isNewInsertionStatus: Bool
        public let isNewInsertionStatusAuthor: Bool
        
        public init(
            notification: MastodonNotification,
            isNewInsertion: Bool,
            isNewInsertionAccount: Bool,
            isNewInsertionStatus: Bool,
            isNewInsertionStatusAuthor: Bool
        ) {
            self.notification = notification
            self.isNewInsertion = isNewInsertion
            self.isNewInsertionAccount = isNewInsertionAccount
            self.isNewInsertionStatus = isNewInsertionStatus
            self.isNewInsertionStatusAuthor = isNewInsertionStatusAuthor
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.MastodonNotification.PersistResult", category: "Persist")
        public func log() {
//            let statusInsertionFlag = isNewInsertion ? "+" : "-"
//            let authorInsertionFlag = isNewInsertionAuthor ? "+" : "-"
//            let contentPreview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
//            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(statusInsertionFlag)](\(status.id))[\(authorInsertionFlag)](\(status.author.id))@\(status.author.username): \(contentPreview)")
        }
        #endif
    }

    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(notification: old, context: context)
            return PersistResult(
                notification: old,
                isNewInsertion: false,
                isNewInsertionAccount: false,
                isNewInsertionStatus: false,
                isNewInsertionStatusAuthor: false
            )
        } else {
            let accountResult = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: context.domain,
                    entity: context.entity.account,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            
            let statusResult: Persistence.MastodonStatus.PersistResult? = {
                guard let entity = context.entity.status else { return nil }
                return Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonStatus.PersistContext(
                        domain: context.domain,
                        entity: entity,
                        me: context.me,
                        statusCache: context.statusCache,
                        userCache: context.userCache,
                        networkDate: context.networkDate
                    )
                )
            }()
            
            let relationship = MastodonNotification.Relationship(
                account: accountResult.user,
                status: statusResult?.status
            )
            
            let notification = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )
            
            return PersistResult(
                notification: notification,
                isNewInsertion: true,
                isNewInsertionAccount: accountResult.isNewInsertion,
                isNewInsertionStatus: statusResult?.isNewInsertion ?? false,
                isNewInsertionStatusAuthor: statusResult?.isNewInsertionAuthor ?? false
            )
        }
    }
    
}

extension Persistence.MastodonNotification {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonNotification? {
        if let cache = context.notificationCache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = MastodonNotification.sortedFetchRequest
            request.predicate = MastodonNotification.predicate(
                domain: context.me.domain,
                userID: context.me.id,
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
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext,
        relationship: MastodonNotification.Relationship
    ) -> MastodonNotification {
        let propery = MastodonNotification.Property(
            entity: context.entity,
            domain: context.me.domain,
            userID: context.me.id,
            networkDate: context.networkDate
        )
        let notification = MastodonNotification.insert(
            into: managedObjectContext,
            property: propery,
            relationship: relationship
        )
        update(notification: notification, context: context)
        return notification
    }
    
    public static func merge(
        notification: MastodonNotification,
        context: PersistContext
    ) {
        guard context.networkDate > notification.updatedAt else { return }
        let property = MastodonNotification.Property(
            entity: context.entity,
            domain: context.me.domain,
            userID: context.me.id,
            networkDate: context.networkDate
        )
        notification.update(property: property)
        update(notification: notification, context: context)
    }
}

extension Persistence.MastodonNotification {
    
    private static func update(
        notification: MastodonNotification,
        context: PersistContext
    ) {
        // TODO:
    }
    
}
