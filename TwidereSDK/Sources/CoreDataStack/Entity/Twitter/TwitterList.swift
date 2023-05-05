//
//  TwitterList.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation
import CoreData

final public class TwitterList: NSManagedObject {
    
    public typealias ID = String

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var name: String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var `private`: Bool
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var memberCount: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var followerCount: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var theDescription: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var activeAt: Date?
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var owner: TwitterUser
    
}

extension TwitterList {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> TwitterList {
        let object: TwitterList = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
    
}

extension TwitterList: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterList.id, ascending: false)]
    }
}

extension TwitterList {
        
    public static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterList.id), id)
    }
    
    public static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterList.id), ids)
    }
    
}

// MARK: - AutoGenerateProperty
extension TwitterList: AutoGenerateProperty {
    // sourcery:inline:TwitterList.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let name: String
        public let `private`: Bool
        public let memberCount: Int64
        public let followerCount: Int64
        public let theDescription: String?
        public let createdAt: Date?
        public let updatedAt: Date

    	public init(
    		id: ID,
    		name: String,
    		`private`: Bool,
    		memberCount: Int64,
    		followerCount: Int64,
    		theDescription: String?,
    		createdAt: Date?,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.name = name
    		self.`private` = `private`
    		self.memberCount = memberCount
    		self.followerCount = followerCount
    		self.theDescription = theDescription
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.name = property.name
    	self.`private` = property.`private`
    	self.memberCount = property.memberCount
    	self.followerCount = property.followerCount
    	self.theDescription = property.theDescription
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(name: property.name)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension TwitterList: AutoGenerateRelationship {
    // sourcery:inline:TwitterList.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let owner: TwitterUser

    	public init(
    		owner: TwitterUser
    	) {
    		self.owner = owner
    	}
    }

    public func configure(relationship: Relationship) {
    	self.owner = relationship.owner
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterList: AutoUpdatableObject {
    // sourcery:inline:TwitterList.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(name: String) {
    	if self.name != name {
    		self.name = name
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(activeAt: Date?) {
    	if self.activeAt != activeAt {
    		self.activeAt = activeAt
    	}
    }
    // sourcery:end
    
    public func update(`private`: Bool) {
        if self.`private` != `private` {
            self.`private` = `private`
        }
    }
    public func update(memberCount: Int64) {
        if self.memberCount != memberCount {
            self.memberCount = memberCount
        }
    }
    public func update(followerCount: Int64) {
        if self.followerCount != followerCount {
            self.followerCount = followerCount
        }
    }
    public func update(theDescription: String?) {
        if self.theDescription != theDescription {
            self.theDescription = theDescription
        }
    }
    public func update(createdAt: Date?) {
        if self.createdAt != createdAt {
            self.createdAt = createdAt
        }
    }
}
