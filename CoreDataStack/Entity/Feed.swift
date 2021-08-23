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
        
    // sourcery: skipAutoUpdatableObject
    @NSManaged public private(set) var acct: String       // {userID}@{domain}
    @NSManaged public private(set) var kindRaw: String
    @NSManaged public private(set) var hasMore: Bool

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // sourcery:begin: skipAutoGenerateProperty
    // one-to-one relationship
    @NSManaged public private(set) var twitterStatus: TwitterStatus?
    // sourcery:end
}

extension Feed {
    public enum Kind: String, CaseIterable {
        case none
        case home
        case notification
    }
    
    public var kind: Kind {
        return Kind(rawValue: kindRaw) ?? .none
    }
    
    public enum Acct {
        case twitter(userID: TwitterUser.ID)
        case mastodon(domain: String, userID: MastodonUser.ID)
        
        public var value: String {
            switch self {
            case .twitter(let userID):
                return "\(userID)@twitter.com"
            case .mastodon(let domain, let userID):
                return "\(userID)@\(domain)"
            }
        }
    }
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
    	public let  kindRaw: String
    	public let  hasMore: Bool
    	public let  createdAt: Date
    	public let  updatedAt: Date

    	public init(
    		acct: String,
    		kindRaw: String,
    		hasMore: Bool,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.acct = acct
    		self.kindRaw = kindRaw
    		self.hasMore = hasMore
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.acct = property.acct
    	self.kindRaw = property.kindRaw
    	self.hasMore = property.hasMore
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(kindRaw: property.kindRaw)
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
    public func update(kindRaw: String) {
    	if self.kindRaw != kindRaw {
    		self.kindRaw = kindRaw
    	}
    }
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
    public func update(twitterStatus: TwitterStatus?) {
    	if self.twitterStatus != twitterStatus {
    		self.twitterStatus = twitterStatus
    	}
    }
    // sourcery:end
}

