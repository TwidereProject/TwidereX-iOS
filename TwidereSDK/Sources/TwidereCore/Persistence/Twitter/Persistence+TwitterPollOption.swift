//
//  Persistence+TwitterPollOption.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterPollOption {
    
    public struct PersistContext {
        public let entity: Twitter.Entity.V2.Tweet.Poll.Option
        public let me: TwitterUser?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.Entity.V2.Tweet.Poll.Option,
            me: TwitterUser?,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let option: TwitterPollOption
        public let isNewInsertion: Bool
        
        public init(
            option: TwitterPollOption,
            isNewInsertion: Bool
        ) {
            self.option = option
            self.isNewInsertion = isNewInsertion
        }
    }
    
    // the bare Poll.Option entity not supports merge from entity.
    // use merge entry on MastodonPoll with exists option objects
    public static func persist(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        let option = create(in: managedObjectContext, context: context)
        return PersistResult(option: option, isNewInsertion: true)
    }
    
}

extension Persistence.TwitterPollOption {
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterPollOption {
        let property = TwitterPollOption.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        let option = TwitterPollOption.insert(
            into: managedObjectContext,
            property: property
        )
        update(option: option, context: context)
        return option
    }
    
    public static func merge(
        option: TwitterPollOption,
        context: PersistContext
    ) {
        assert(option.position == Int64(context.entity.position))
        guard context.networkDate > option.updatedAt else { return }
        let property = TwitterPollOption.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        option.update(property: property)
        update(option: option, context: context)
    }
    
    private static func update(
        option: TwitterPollOption,
        context: PersistContext
    ) {
        // Do nothing
    }   // end func update

}
