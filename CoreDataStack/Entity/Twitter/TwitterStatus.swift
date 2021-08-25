//
//  TwitterStatus.swift
//  TwitterStatus
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class TwitterStatus: NSManagedObject {

    public typealias ID = String
    
    // sourcery: skipAutoUpdatableObject
    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var text: String
    
    // sourcery: skipAutoUpdatableObject
    @NSManaged public private(set) var attachmentsRaw: Data?
    
    @NSManaged public private(set) var likeCount: Int
    // sourcery: skipAutoUpdatableObject
    @NSManaged public private(set) var replyCount: Int
    @NSManaged public private(set) var repostCount: Int

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // sourcery:begin: skipAutoUpdatableObject, skipAutoGenerateProperty
    
    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var author: TwitterUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var repost: TwitterStatus?
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var quote: TwitterStatus?
    
    // one-to-many relationship
    @NSManaged public private(set) var repostFrom: Set<TwitterStatus>
    @NSManaged public private(set) var quoteFrom: Set<TwitterStatus>
    
    // sourcery:end
}

extension TwitterStatus {
    public var attachments: [TwitterAttachment] {
        guard let data = attachmentsRaw else { return [] }
        do {
            let attachments = try JSONDecoder().decode([TwitterAttachment].self, from: data)
            return attachments
        } catch {
            assertionFailure(error.localizedDescription)
            return []
        }
    }
}

extension TwitterStatus {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> TwitterStatus {
        let object: TwitterStatus = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
    
}

extension TwitterStatus: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterStatus.createdAt, ascending: false)]
    }
}

extension TwitterStatus {
    
    public static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterStatus.id), id)
    }
    
    public static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterStatus.id), ids)
    }
    
}

// MARK: - AutoGenerateProperty
extension TwitterStatus: AutoGenerateProperty {
    // sourcery:inline:TwitterStatus.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
    	public let  id: ID
    	public let  text: String
    	public let  attachmentsRaw: Data?
    	public let  likeCount: Int
    	public let  replyCount: Int
    	public let  repostCount: Int
    	public let  createdAt: Date
    	public let  updatedAt: Date

    	public init(
    		id: ID,
    		text: String,
    		attachmentsRaw: Data?,
    		likeCount: Int,
    		replyCount: Int,
    		repostCount: Int,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.text = text
    		self.attachmentsRaw = attachmentsRaw
    		self.likeCount = likeCount
    		self.replyCount = replyCount
    		self.repostCount = repostCount
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.text = property.text
    	self.attachmentsRaw = property.attachmentsRaw
    	self.likeCount = property.likeCount
    	self.replyCount = property.replyCount
    	self.repostCount = property.repostCount
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(text: property.text)
    	update(likeCount: property.likeCount)
    	update(repostCount: property.repostCount)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension TwitterStatus: AutoGenerateRelationship {
    // sourcery:inline:TwitterStatus.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let  author: TwitterUser
    	public let  repost: TwitterStatus?
    	public let  quote: TwitterStatus?

    	public init(
    		author: TwitterUser,
    		repost: TwitterStatus?,
    		quote: TwitterStatus?
    	) {
    		self.author = author
    		self.repost = repost
    		self.quote = quote
    	}
    }

    public func configure(relationship: Relationship) {
    	self.author = relationship.author
    	self.repost = relationship.repost
    	self.quote = relationship.quote
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterStatus: AutoUpdatableObject {
    // sourcery:inline:TwitterStatus.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(text: String) {
    	if self.text != text {
    		self.text = text
    	}
    }
    public func update(likeCount: Int) {
    	if self.likeCount != likeCount {
    		self.likeCount = likeCount
    	}
    }
    public func update(repostCount: Int) {
    	if self.repostCount != repostCount {
    		self.repostCount = repostCount
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

extension TwitterStatus {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(TwitterStatus.feeds)).add(feed)
    }
}
