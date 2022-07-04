//
//  MastodonNotification.swift
//  CoreDataStack
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class MastodonNotification: NSManagedObject {
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var userID: String
    
    @NSManaged public private(set) var typeRaw: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    public var notificationType: MastodonNotificationType {
        get {
            let rawValue = typeRaw
            return MastodonNotificationType(rawValue: rawValue) ?? ._other(rawValue)
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isFollowRequestBusy: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var account: MastodonUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var status: MastodonStatus?
    
}

extension MastodonNotification: FeedIndexable { }

extension MastodonNotification {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> MastodonNotification {
        let object: MastodonNotification = context.insertObject()
        object.configure(property: property)
        object.configure(relationship: relationship)
        return object
    }
    
}

extension MastodonNotification: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonNotification.createdAt, ascending: false)]
    }
}

extension MastodonNotification {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.domain), domain)
    }
    
    static func predicate(userID: MastodonUser.ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.userID), userID)
    }
    
    static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.id), id)
    }
    
    public static func predicate(domain: String, userID: MastodonUser.ID, id: ID) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonNotification.predicate(domain: domain),
            MastodonNotification.predicate(userID: userID),
            MastodonNotification.predicate(id: id),
        ])
    }
    
}

// MARK: - AutoGenerateProperty
extension MastodonNotification: AutoGenerateProperty {
    // sourcery:inline:MastodonNotification.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let domain: String
        public let userID: String
        public let notificationType: MastodonNotificationType
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		id: ID,
    		domain: String,
    		userID: String,
    		notificationType: MastodonNotificationType,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.domain = domain
    		self.userID = userID
    		self.notificationType = notificationType
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.domain = property.domain
    	self.userID = property.userID
    	self.notificationType = property.notificationType
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(notificationType: property.notificationType)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonNotification: AutoGenerateRelationship {
    // sourcery:inline:MastodonNotification.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let account: MastodonUser
    	public let status: MastodonStatus?

    	public init(
    		account: MastodonUser,
    		status: MastodonStatus?
    	) {
    		self.account = account
    		self.status = status
    	}
    }

    public func configure(relationship: Relationship) {
    	self.account = relationship.account
    	self.status = relationship.status
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonNotification: AutoUpdatableObject {
    // sourcery:inline:MastodonNotification.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(notificationType: MastodonNotificationType) {
    	if self.notificationType != notificationType {
    		self.notificationType = notificationType
    	}
    }
    public func update(isFollowRequestBusy: Bool) {
    	if self.isFollowRequestBusy != isFollowRequestBusy {
    		self.isFollowRequestBusy = isFollowRequestBusy
    	}
    }
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}

extension MastodonNotification {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(MastodonNotification.feeds)).add(feed)
    }
}
