//
//  Persistence+MastodonPollOption.swift
//  
//
//  Created by MainasuK on 2021-12-9.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonPollOption {
    
    public struct PersistContext {
        public let index: Int
        public let entity: Mastodon.Entity.Poll.Option
        public let me: MastodonUser?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            index: Int,
            entity: Mastodon.Entity.Poll.Option,
            me: MastodonUser?,
            networkDate: Date
        ) {
            self.index = index
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let option: MastodonPollOption
        public let isNewInsertion: Bool
        
        public init(
            option: MastodonPollOption,
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

extension Persistence.MastodonPollOption {
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonPollOption {
        let property = MastodonPollOption.Property(
            index: context.index,
            entity: context.entity,
            networkDate: context.networkDate
        )
        let option = MastodonPollOption.insert(into: managedObjectContext, property: property)
        update(option: option, context: context)
        return option
    }
    
    public static func merge(
        option: MastodonPollOption,
        context: PersistContext
    ) {
        assert(option.index == context.index)
        guard context.networkDate > option.updatedAt else { return }
        let property = MastodonPollOption.Property(
            index: context.index,
            entity: context.entity,
            networkDate: context.networkDate
        )
        option.update(property: property)
        update(option: option, context: context)
    }
    
    private static func update(
        option: MastodonPollOption,
        context: PersistContext
    ) {
        // Do nothing
    }   // end func update

}
