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

    struct PersistContext {
        let domain: String
        let entity: Mastodon.Entity.Notification
        let me: MastodonUser?
        let notificationCache: Persistence.PersistCache<MastodonNotification>?
        let statusCache: Persistence.PersistCache<MastodonStatus>?
        let userCache: Persistence.PersistCache<MastodonUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    struct PersistResult {
        let notification: MastodonNotification
        let isNewInsertion: Bool
        let isNewInsertionAccount: Bool
        let isNewInsertionStatus: Bool
        let isNewInsertionStatusAuthor: Bool
        
        #if DEBUG
        let logger = Logger(subsystem: "Persistence.MastodonNotification.PersistResult", category: "Persist")
        func log() {
//            let statusInsertionFlag = isNewInsertion ? "+" : "-"
//            let authorInsertionFlag = isNewInsertionAuthor ? "+" : "-"
//            let contentPreview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
//            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(statusInsertionFlag)](\(status.id))[\(authorInsertionFlag)](\(status.author.id))@\(status.author.username): \(contentPreview)")
        }
        #endif
    }

    static func createOrMerge(
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
    
    static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonNotification? {
        if let cache = context.notificationCache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = MastodonNotification.sortedFetchRequest
            request.predicate = MastodonNotification.predicate(domain: context.domain, id: context.entity.id)
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
        relationship: MastodonNotification.Relationship
    ) -> MastodonNotification {
        let propery = MastodonNotification.Property(
            entity: context.entity,
            domain: context.domain,
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
    
    static func merge(
        notification: MastodonNotification,
        context: PersistContext
    ) {
        guard context.networkDate > notification.updatedAt else { return }
        let property = MastodonNotification.Property(
            entity: context.entity,
            domain: context.domain,
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
