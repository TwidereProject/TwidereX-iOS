//
//  Persistence+TwitterPoll.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import CoreData
import CoreDataStack
import Foundation
import TwitterSDK
import os.log

extension Persistence.TwitterPoll {

    public struct PersistContext {
        public let entity: Twitter.Entity.V2.Tweet.Poll
        public let me: TwitterUser?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            entity: Twitter.Entity.V2.Tweet.Poll,
            me: TwitterUser?,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }

    public struct PersistResult {
        public let poll: TwitterPoll
        public let isNewInsertion: Bool
        
        public init(
            poll: TwitterPoll,
            isNewInsertion: Bool
        ) {
            self.poll = poll
            self.isNewInsertion = isNewInsertion
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.TwitterPoll.PersistResult", category: "Persist")
        public func log() {
            let pollInsertionFlag = isNewInsertion ? "+" : "-"
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(pollInsertionFlag)](\(poll.id)):")
        }
        #endif
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(poll: old, context: context)
            return PersistResult(
                poll: old,
                isNewInsertion: false
            )
        } else {
            let poll = create(
                in: managedObjectContext,
                context: context
            )
            return PersistResult(
                poll: poll,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.TwitterPoll {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterPoll? {
        let request = TwitterPoll.sortedFetchRequest
        request.predicate = TwitterPoll.predicate(id: context.entity.id)
        request.fetchLimit = 1
        do {
            return try managedObjectContext.fetch(request).first
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> TwitterPoll {
        let property = TwitterPoll.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        let poll = TwitterPoll.insert(
            into: managedObjectContext,
            property: property
        )
        
        let options: [TwitterPollOption] = context.entity.options.enumerated().map { i, entity in
            let optionResult = Persistence.TwitterPollOption.persist(
                in: managedObjectContext,
                context: Persistence.TwitterPollOption.PersistContext(
                    entity: entity,
                    me: context.me,
                    networkDate: context.networkDate
                )
            )
            return optionResult.option
        }
        poll.attach(options: options)
        
        update(poll: poll, context: context)
        return poll
    }
    
    public static func merge(
        poll: TwitterPoll,
        context: PersistContext
    ) {
        guard context.networkDate > poll.updatedAt else { return }
        let property = TwitterPoll.Property(
            entity: context.entity,
            networkDate: context.networkDate
        )
        poll.update(property: property)
        update(poll: poll, context: context)
    }
    
    public static func update(
        poll: TwitterPoll,
        context: PersistContext
    ) {
        let optionEntities = context.entity.options
        let options = poll.options.sorted(by: { $0.position < $1.position })
        for (option, entity) in zip(options, optionEntities) {
            Persistence.TwitterPollOption.merge(
                option: option,
                context: Persistence.TwitterPollOption.PersistContext(
                    entity: entity,
                    me: context.me,
                    networkDate: context.networkDate
                )
            )
        }   // end for in

        poll.update(updatedAt: context.networkDate)
    }
    
}
