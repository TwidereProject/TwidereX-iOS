//
//  MastodonPoll.swift
//  
//
//  Created by MainasuK on 2021-12-9.
//

import Foundation
import CoreData

public final class MastodonPoll: NSManagedObject {
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var expired: Bool
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var multiple: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votersCount: Int64
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isVoting: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var expiresAt: Date?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    
    // one-to-one relationship
    @NSManaged public private(set) var status: MastodonStatus
    
    // one-to-many relationship
    @NSManaged public private(set) var options: Set<MastodonPollOption>
    
    // many-to-many relationship
    @NSManaged public private(set) var voteBy: Set<MastodonUser>
}

extension MastodonPoll {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> MastodonPoll {
        let object: MastodonPoll = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension MastodonPoll: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonPoll.createdAt, ascending: false)]
    }
}

extension MastodonPoll {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonPoll.domain), domain)
    }
    
    static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonPoll.id), id)
    }

    static func predicate(ids: [ID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonPoll.id), ids)
    }
    
    public static func predicate(domain: String, id: ID) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(id: id)
        ])
    }
    
    public static func predicate(domain: String, ids: [ID]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(ids: ids)
        ])
    }
}

// MARK: - AutoGenerateProperty
extension MastodonPoll: AutoGenerateProperty {
    // sourcery:inline:MastodonPoll.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let domain: String
        public let id: ID
        public let expired: Bool
        public let multiple: Bool
        public let votesCount: Int64
        public let votersCount: Int64
        public let expiresAt: Date?
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		domain: String,
    		id: ID,
    		expired: Bool,
    		multiple: Bool,
    		votesCount: Int64,
    		votersCount: Int64,
    		expiresAt: Date?,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.domain = domain
    		self.id = id
    		self.expired = expired
    		self.multiple = multiple
    		self.votesCount = votesCount
    		self.votersCount = votersCount
    		self.expiresAt = expiresAt
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.domain = property.domain
    	self.id = property.id
    	self.expired = property.expired
    	self.multiple = property.multiple
    	self.votesCount = property.votesCount
    	self.votersCount = property.votersCount
    	self.expiresAt = property.expiresAt
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(expired: property.expired)
    	update(votesCount: property.votesCount)
    	update(votersCount: property.votersCount)
    	update(expiresAt: property.expiresAt)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end

}

// MARK: - AutoUpdatableObject
extension MastodonPoll: AutoUpdatableObject {
    // sourcery:inline:MastodonPoll.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(expired: Bool) {
    	if self.expired != expired {
    		self.expired = expired
    	}
    }
    public func update(votesCount: Int64) {
    	if self.votesCount != votesCount {
    		self.votesCount = votesCount
    	}
    }
    public func update(votersCount: Int64) {
    	if self.votersCount != votersCount {
    		self.votersCount = votersCount
    	}
    }
    public func update(isVoting: Bool) {
    	if self.isVoting != isVoting {
    		self.isVoting = isVoting
    	}
    }
    public func update(expiresAt: Date?) {
    	if self.expiresAt != expiresAt {
    		self.expiresAt = expiresAt
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }

    // sourcery:end
    
    public func update(isVote: Bool, by user: MastodonUser) {
        if isVote {
            if !voteBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonPoll.voteBy)).add(user)
            }
        } else {
            if voteBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonPoll.voteBy)).remove(user)
            }
        }
    }
    
    public func attach(options: [MastodonPollOption]) {
        for option in options {
            guard !self.options.contains(option) else { continue }
            self.mutableSetValue(forKey: #keyPath(MastodonPoll.options)).add(option)
        }
    }
}
