//
//  DataSourceFacade+History.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import TwidereCore

extension DataSourceFacade {

    static func recordStatusHistory(
        denpendency: NeedsDependency,
        status: StatusRecord
    ) async {
        let now = Date()
        guard let authenticationContext = denpendency.context.authenticationService.activeAuthenticationContext else { return }

        let acct = authenticationContext.acct
        let managedObjectContext = denpendency.context.backgroundManagedObjectContext
        let _history: ManagedObjectRecord<History>? = await managedObjectContext.perform {
            guard let status = status.object(in: managedObjectContext) else { return nil }
            guard let history = status.histories.first(where: { $0.acct == acct }) else { return nil }
            return history.asRecrod
        }
        
        if let history = _history {
            try? await managedObjectContext.performChanges {
                guard let history = history.object(in: managedObjectContext) else { return }
                history.update(timestamp: now)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status history for: \(history.debugDescription)")
            }
        } else {
            try? await managedObjectContext.performChanges {
                guard let status = status.object(in: managedObjectContext) else { return }
                let history = History.insert(
                    into: managedObjectContext,
                    property: .init(acct: acct, timestamp: now, createdAt: now)
                )
                switch status {
                case .twitter(let object):
                    history.update(twitterStatus: object)
                case .mastodon(let object):
                    history.update(mastodonStatus: object)
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create status history: \(history.debugDescription)")

            }
        }
    }   // end func

    static func recordUserHistory(
        denpendency: NeedsDependency,
        user: UserRecord
    ) async {
        let now = Date()
        guard let authenticationContext = denpendency.context.authenticationService.activeAuthenticationContext else { return }
        
        let acct = authenticationContext.acct
        let managedObjectContext = denpendency.context.backgroundManagedObjectContext
        let _history: ManagedObjectRecord<History>? = await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return nil }
            guard let history = user.histories.first(where: { $0.acct == acct }) else { return nil }
            return history.asRecrod
        }
        
        if let history = _history {
            try? await managedObjectContext.performChanges {
                guard let history = history.object(in: managedObjectContext) else { return }
                history.update(timestamp: now)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update user history for: \(history.debugDescription)")
            }
        } else {
            try? await managedObjectContext.performChanges {
                guard let user = user.object(in: managedObjectContext) else { return }
                let history = History.insert(
                    into: managedObjectContext,
                    property: .init(acct: acct, timestamp: now, createdAt: now)
                )
                switch user {
                case .twitter(let object):
                    history.update(twitterUser: object)
                case .mastodon(let object):
                    history.update(mastodonUser: object)
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create user history: \(history.debugDescription)")

            }
        }
    }
    
}
