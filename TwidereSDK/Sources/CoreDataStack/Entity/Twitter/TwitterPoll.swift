//
//  TwitterPoll.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import Foundation
import CoreData

public final class TwitterPoll: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    @NSManaged public private(set) var votingStatusRaw: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    public private(set) var votingStatus: VotingStatus {
        get {
            VotingStatus(rawValue: votingStatusRaw) ?? .closed
        }
        set {
            votingStatusRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var durationMinutes: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var endDatetime: Date?
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var status: TwitterStatus
    
    // one-to-many relationship
    @NSManaged public private(set) var options: Set<TwitterPollOption>
    
}

extension TwitterPoll {
    public enum VotingStatus: String, CaseIterable {
        case open
        case closed
    }
}

extension TwitterPoll {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterPoll {
        let object: TwitterPoll = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension TwitterPoll: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPoll.createdAt, ascending: false)]
    }
}

extension TwitterPoll {
    
    public static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterPoll.id), id)
    }
    
}

// MARK: - AutoGenerateProperty
extension TwitterPoll: AutoGenerateProperty {
    // sourcery:inline:TwitterPoll.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let votingStatus: VotingStatus
        public let durationMinutes: Int64
        public let endDatetime: Date?
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		id: ID,
    		votingStatus: VotingStatus,
    		durationMinutes: Int64,
    		endDatetime: Date?,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.votingStatus = votingStatus
    		self.durationMinutes = durationMinutes
    		self.endDatetime = endDatetime
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.votingStatus = property.votingStatus
    	self.durationMinutes = property.durationMinutes
    	self.endDatetime = property.endDatetime
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(votingStatus: property.votingStatus)
    	update(durationMinutes: property.durationMinutes)
    	update(endDatetime: property.endDatetime)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterPoll: AutoUpdatableObject {
    // sourcery:inline:TwitterPoll.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(votingStatus: VotingStatus) {
    	if self.votingStatus != votingStatus {
    		self.votingStatus = votingStatus
    	}
    }
    public func update(durationMinutes: Int64) {
    	if self.durationMinutes != durationMinutes {
    		self.durationMinutes = durationMinutes
    	}
    }
    public func update(endDatetime: Date?) {
    	if self.endDatetime != endDatetime {
    		self.endDatetime = endDatetime
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
    
    public func attach(options: [TwitterPollOption]) {
        for option in options {
            guard !self.options.contains(option) else { continue }
            self.mutableSetValue(forKey: #keyPath(TwitterPoll.options)).add(option)
        }
    }
}
