//
//  MastodonStatus.swift
//  MastodonStatus
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class MastodonStatus: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var uri: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var content: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var likeCount: Int
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyCount: Int
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var repostCount: Int
    
    @NSManaged public private(set) var visibilityRaw: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    public var visibility: MastodonVisibility {
        get {
            let rawValue = visibilityRaw
            return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
        }
        set {
            visibilityRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var text: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var language: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>

    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var author: MastodonUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var repost: MastodonStatus?

    // one-to-many relationship
    @NSManaged public private(set) var repostFrom: Set<MastodonStatus>
    
}

extension MastodonStatus {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var attachments: [MastodonAttachment] {
        get {
            let keyPath = #keyPath(MastodonStatus.attachments)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let attachments = try JSONDecoder().decode([MastodonAttachment].self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(MastodonStatus.attachments)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension MastodonStatus {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> MastodonStatus {
        let object: MastodonStatus = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
    
}

extension MastodonStatus: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonStatus.createdAt, ascending: false)]
    }
}

extension MastodonStatus {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonStatus.domain), domain)
    }
    
    static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonStatus.id), id)
    }

    static func predicate(ids: [ID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonStatus.id), ids)
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
extension MastodonStatus: AutoGenerateProperty {
    // sourcery:inline:MastodonStatus.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let  id: ID
        public let  domain: String
        public let  uri: String
        public let  content: String
        public let  likeCount: Int
        public let  replyCount: Int
        public let  repostCount: Int
        public let  visibility: MastodonVisibility
        public let  url: String?
        public let  text: String?
        public let  language: String?
        public let  createdAt: Date
        public let  updatedAt: Date
        public let  attachments: [MastodonAttachment]

    	public init(
    		id: ID,
    		domain: String,
    		uri: String,
    		content: String,
    		likeCount: Int,
    		replyCount: Int,
    		repostCount: Int,
    		visibility: MastodonVisibility,
    		url: String?,
    		text: String?,
    		language: String?,
    		createdAt: Date,
    		updatedAt: Date,
    		attachments: [MastodonAttachment]
    	) {
    		self.id = id
    		self.domain = domain
    		self.uri = uri
    		self.content = content
    		self.likeCount = likeCount
    		self.replyCount = replyCount
    		self.repostCount = repostCount
    		self.visibility = visibility
    		self.url = url
    		self.text = text
    		self.language = language
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.attachments = attachments
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.domain = property.domain
    	self.uri = property.uri
    	self.content = property.content
    	self.likeCount = property.likeCount
    	self.replyCount = property.replyCount
    	self.repostCount = property.repostCount
    	self.visibility = property.visibility
    	self.url = property.url
    	self.text = property.text
    	self.language = property.language
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.attachments = property.attachments
    }

    public func update(property: Property) {
    	update(content: property.content)
    	update(likeCount: property.likeCount)
    	update(replyCount: property.replyCount)
    	update(repostCount: property.repostCount)
    	update(visibility: property.visibility)
    	update(url: property.url)
    	update(text: property.text)
    	update(language: property.language)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    	update(attachments: property.attachments)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonStatus: AutoGenerateRelationship {
    // sourcery:inline:MastodonStatus.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let  author: MastodonUser
    	public let  repost: MastodonStatus?

    	public init(
    		author: MastodonUser,
    		repost: MastodonStatus?
    	) {
    		self.author = author
    		self.repost = repost
    	}
    }

    public func configure(relationship: Relationship) {
    	self.author = relationship.author
    	self.repost = relationship.repost
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonStatus: AutoUpdatableObject {
    // sourcery:inline:MastodonStatus.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(content: String) {
    	if self.content != content {
    		self.content = content
    	}
    }
    public func update(likeCount: Int) {
    	if self.likeCount != likeCount {
    		self.likeCount = likeCount
    	}
    }
    public func update(replyCount: Int) {
    	if self.replyCount != replyCount {
    		self.replyCount = replyCount
    	}
    }
    public func update(repostCount: Int) {
    	if self.repostCount != repostCount {
    		self.repostCount = repostCount
    	}
    }
    public func update(visibility: MastodonVisibility) {
    	if self.visibility != visibility {
    		self.visibility = visibility
    	}
    }
    public func update(url: String?) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(text: String?) {
    	if self.text != text {
    		self.text = text
    	}
    }
    public func update(language: String?) {
    	if self.language != language {
    		self.language = language
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
    public func update(attachments: [MastodonAttachment]) {
    	if self.attachments != attachments {
    		self.attachments = attachments
    	}
    }
    // sourcery:end
}

extension MastodonStatus {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(MastodonStatus.feeds)).add(feed)
    }
}
