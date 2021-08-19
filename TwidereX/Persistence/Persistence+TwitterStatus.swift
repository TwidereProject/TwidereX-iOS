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
        let domain: String
        let entities: [Twitter.Entity.Tweet]
        // let cache: APIService.Persist.PersistCache<MastodonUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) async throws {
    
        try await managedObjectContext.performChanges {
            let request = batchInsertRequest(context: context)
            try managedObjectContext.execute(request)
        }
    }
    
}

extension Persistence.TwitterStatus {

    private static func batchInsertRequest(context: PersistContext) -> NSBatchInsertRequest {
        var index = 0
        let count = context.entities.count
        
        let request = NSBatchInsertRequest(
            entity: TwitterStatus.entity()
        ) { (object: NSManagedObject) -> Bool in
            guard index < count else { return true }
            if let status = object as? TwitterStatus {
                let property = TwitterStatus.Property(
                    entity: context.entities[index],
                    networkDate: context.networkDate
                )
                status.configure(property: property)
            }
            index += 1
            return false
        }
        
        return request
    }
    
}
