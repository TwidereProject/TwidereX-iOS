//
//  TwitterSavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation
import CoreData

public final class TwitterSavedSearch: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var name: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var query: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var user: TwitterUser
    
}

extension TwitterSavedSearch {

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> TwitterSavedSearch {
        let object: TwitterSavedSearch = context.insertObject()
        object.configure(property: property)
        object.configure(relationship: relationship)
        return object
    }
    
}

extension TwitterSavedSearch: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterSavedSearch.createdAt, ascending: false)]
    }
}

extension TwitterSavedSearch {
    
    public static func hasTwitterUserPredicate() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(TwitterSavedSearch.user))
    }
    
    public static func predicate(userID: TwitterUser.ID) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            hasTwitterUserPredicate(),
            NSPredicate(format: "%K == %@", #keyPath(TwitterSavedSearch.user.id), userID)
        ])
    }
    
    public static func predicate(id: ID) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(TwitterSavedSearch.id), id)
        ])
    }
    
}

// MARK: - TwitterSavedSearch
extension TwitterSavedSearch: AutoGenerateProperty {
    // sourcery:inline:TwitterSavedSearch.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let  id: ID
        public let  name: String
        public let  query: String
        public let  createdAt: Date

    	public init(
    		id: ID,
    		name: String,
    		query: String,
    		createdAt: Date
    	) {
    		self.id = id
    		self.name = name
    		self.query = query
    		self.createdAt = createdAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.name = property.name
    	self.query = property.query
    	self.createdAt = property.createdAt
    }

    public func update(property: Property) {
    	update(name: property.name)
    	update(query: property.query)
    	update(createdAt: property.createdAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension TwitterSavedSearch: AutoGenerateRelationship {
    // sourcery:inline:TwitterSavedSearch.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let user: TwitterUser

    	public init(
    		user: TwitterUser
    	) {
    		self.user = user
    	}
    }

    public func configure(relationship: Relationship) {
    	self.user = relationship.user
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterSavedSearch: AutoUpdatableObject {
    // sourcery:inline:TwitterSavedSearch.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(name: String) {
    	if self.name != name {
    		self.name = name
    	}
    }
    public func update(query: String) {
    	if self.query != query {
    		self.query = query
    	}
    }
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    
    // sourcery:end
}
