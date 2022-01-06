//
//  MastodonSavedSearch.swift
//  
//
//  Created by MainasuK on 2022-1-6.
//

import Foundation
import CoreData

public final class MastodonSavedSearch: NSManagedObject {
    

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var query: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var user: MastodonUser
    
}

extension MastodonSavedSearch {

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> MastodonSavedSearch {
        let object: MastodonSavedSearch = context.insertObject()
        object.configure(property: property)
        object.configure(relationship: relationship)
        return object
    }
    
}

extension MastodonSavedSearch: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonSavedSearch.createdAt, ascending: false)]
    }
}

extension MastodonSavedSearch {
    
    public static func hasMastodonUserPredicate() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(MastodonSavedSearch.user))
    }
    
    public static func predicate(userID: MastodonUser.ID, domain: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            hasMastodonUserPredicate(),
            NSPredicate(format: "%K == %@", #keyPath(MastodonSavedSearch.user.id), userID),
            NSPredicate(format: "%K == %@", #keyPath(MastodonSavedSearch.user.domain), domain),
        ])
    }
    
    public static func predicate(userID: MastodonUser.ID, domain: String, query: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            hasMastodonUserPredicate(),
            predicate(userID: userID, domain: domain),
            NSPredicate(format: "%K == %@", #keyPath(MastodonSavedSearch.query), query),
        ])
    }

}

// MARK: - TwitterSavedSearch
extension MastodonSavedSearch: AutoGenerateProperty {
    // sourcery:inline:MastodonSavedSearch.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let query: String
        public let createdAt: Date

    	public init(
    		query: String,
    		createdAt: Date
    	) {
    		self.query = query
    		self.createdAt = createdAt
    	}
    }

    public func configure(property: Property) {
    	self.query = property.query
    	self.createdAt = property.createdAt
    }

    public func update(property: Property) {
    	update(query: property.query)
    	update(createdAt: property.createdAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonSavedSearch: AutoGenerateRelationship {
    // sourcery:inline:MastodonSavedSearch.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let user: MastodonUser

    	public init(
    		user: MastodonUser
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
extension MastodonSavedSearch: AutoUpdatableObject {
    // sourcery:inline:MastodonSavedSearch.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
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
