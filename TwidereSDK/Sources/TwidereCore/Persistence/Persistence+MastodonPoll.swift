//
//  Persistence+MastodonPoll.swift
//  
//
//  Created by MainasuK on 2021-12-9.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonPoll {

    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Poll
        public let me: MastodonUser?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            domain: String,
            entity: Mastodon.Entity.Poll,
            me: MastodonUser?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }

    public struct PersistResult {
        public let poll: MastodonPoll
        public let isNewInsertion: Bool
        
        public init(
            poll: MastodonPoll,
            isNewInsertion: Bool
        ) {
            self.poll = poll
            self.isNewInsertion = isNewInsertion
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.MastodonPoll.PersistResult", category: "Persist")
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
            let options: [MastodonPollOption] = context.entity.options.enumerated().map { i, entity in
                let optionResult = Persistence.MastodonPollOption.persist(
                    in: managedObjectContext,
                    context: Persistence.MastodonPollOption.PersistContext(
                        index: i,
                        entity: entity,
                        me: context.me,
                        networkDate: context.networkDate
                    )
                )
                return optionResult.option
            }
            
            let poll = create(
                in: managedObjectContext,
                context: context
            )
            poll.attach(options: options)

            return PersistResult(
                poll: poll,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.MastodonPoll {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonPoll? {
        let request = MastodonPoll.sortedFetchRequest
        request.predicate = MastodonPoll.predicate(domain: context.domain, id: context.entity.id)
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
    ) -> MastodonPoll {
        let property = MastodonPoll.Property(
            domain: context.domain,
            entity: context.entity,
            networkDate: context.networkDate
        )
        let poll = MastodonPoll.insert(
            into: managedObjectContext,
            property: property
        )
        update(poll: poll, context: context)
        return poll
    }
    
    public static func merge(
        poll: MastodonPoll,
        context: PersistContext
    ) {
        guard context.networkDate > poll.updatedAt else { return }
        let property = MastodonPoll.Property(
            domain: context.domain,
            entity: context.entity,
            networkDate: context.networkDate
        )
        poll.update(property: property)
        update(poll: poll, context: context)
    }
    
    public static func update(
        poll: MastodonPoll,
        context: PersistContext
    ) {
        let optionEntities = context.entity.options
        let options = poll.options.sorted(by: { $0.index < $1.index })
        for (option, entity) in zip(options, optionEntities) {
            Persistence.MastodonPollOption.merge(
                option: option,
                context: Persistence.MastodonPollOption.PersistContext(
                    index: Int(option.index),
                    entity: entity,
                    me: context.me,
                    networkDate: context.networkDate
                )
            )
        }   // end for in
        
        if let me = context.me {
            if let voted = context.entity.voted {
                poll.update(isVote: voted, by: me)
            }
            for option in options {
                let index = Int(option.index)
                let isVote = (context.entity.ownVotes ?? []).contains(index)
                option.update(isVote: isVote, by: me)
            }
        }
        poll.update(updatedAt: context.networkDate)
    }
    
}
