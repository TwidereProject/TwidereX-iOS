//
//  Feed.swift
//  Feed
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class Feed: NSManagedObject {
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var acct: String       // {userID}@{domain}
    
    @NSManaged public private(set) var kindRaw: String
    // sourcery: autoGenerateProperty
    public var kind: Kind {
        get {
            Kind(rawValue: kindRaw) ?? .none
        }
        set {
            kindRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var hasMore: Bool

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var twitterStatus: TwitterStatus?
    @NSManaged public private(set) var mastodonStatus: MastodonStatus?
}

extension Feed {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Feed {
        let object: Feed = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension Feed: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Feed.createdAt, ascending: false)]
    }
}

extension Feed {
    
    static func predicate(kind: Kind) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Feed.kindRaw), kind.rawValue)
    }
    
    static func predicate(acct: Acct) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Feed.acct), acct.value)
    }
    
    public static func predicate(kind: Kind, acct: Acct) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            Feed.predicate(kind: kind),
            Feed.predicate(acct: acct)
        ])
    }

}

// MARK: - AutoGenerateProperty
extension Feed: AutoGenerateProperty {
    // sourcery:inline:Feed.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let  acct: String
        public let  kind: Kind
        public let  hasMore: Bool
        public let  createdAt: Date
        public let  updatedAt: Date

    	public init(
    		acct: String,
    		kind: Kind,
    		hasMore: Bool,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.acct = acct
    		self.kind = kind
    		self.hasMore = hasMore
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.acct = property.acct
    	self.kind = property.kind
    	self.hasMore = property.hasMore
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(hasMore: property.hasMore)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Feed: AutoUpdatableObject {
    // sourcery:inline:Feed.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(hasMore: Bool) {
    	if self.hasMore != hasMore {
    		self.hasMore = hasMore
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

