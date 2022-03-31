//
//  MastodonList.swift
//  
//
//  Created by MainasuK on 2022-3-7.
//

import Foundation
import CoreData

final public class MastodonList: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var title: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var owner: MastodonUser
    
}

extension MastodonList {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> MastodonList {
        let object: MastodonList = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
    
}

extension MastodonList: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonList.id, ascending: false)]
    }
}

extension MastodonList {
    
    private static func predicate(domain: MastodonList.ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonList.domain), domain)
    }
    
    private static func predicate(id: MastodonList.ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonList.id), id)
    }
    
    private static func predicate(ids: [MastodonList.ID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonList.id), ids)
    }
    
    public static func predicate(domain: String, id: MastodonList.ID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(id: id),
        ])
    }
    
    public static func predicate(domain: String, ids: [MastodonList.ID]) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(ids: ids),
        ])
    }
    
}

// MARK: - AutoGenerateProperty
extension MastodonList: AutoGenerateProperty {
    // sourcery:inline:MastodonList.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let domain: ID
        public let title: String
        public let updatedAt: Date

    	public init(
    		id: ID,
    		domain: ID,
    		title: String,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.domain = domain
    		self.title = title
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.domain = property.domain
    	self.title = property.title
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(title: property.title)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonList: AutoGenerateRelationship {
    // sourcery:inline:MastodonList.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let owner: MastodonUser

    	public init(
    		owner: MastodonUser
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
extension MastodonList: AutoUpdatableObject {
    // sourcery:inline:MastodonList.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(title: String) {
    	if self.title != title {
    		self.title = title
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
    
//    public func update(`private`: Bool) {
//        if self.`private` != `private` {
//            self.`private` = `private`
//        }
//    }
//    public func update(memberCount: Int64) {
//        if self.memberCount != memberCount {
//            self.memberCount = memberCount
//        }
//    }
//    public func update(followerCount: Int64) {
//        if self.followerCount != followerCount {
//            self.followerCount = followerCount
//        }
//    }
//    public func update(theDescription: String?) {
//        if self.theDescription != theDescription {
//            self.theDescription = theDescription
//        }
//    }
//    public func update(createdAt: Date?) {
//        if self.createdAt != createdAt {
//            self.createdAt = createdAt
//        }
//    }
}
