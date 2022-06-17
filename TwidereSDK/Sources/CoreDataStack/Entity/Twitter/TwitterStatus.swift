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
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var text: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var likeCount: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var replyCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var repostCount: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var quoteCount: Int64
    
    // Note: not mark `autoUpdatableObject` for `replyCount` and `quoteCount`
    // to avoid V1 API update the exists value to 0
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var language: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var source: String?
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var conversationID: TwitterStatus.ID?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyToStatusID: TwitterStatus.ID?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyToUserID: TwitterUser.ID?

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var poll: TwitterPoll?
        
    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var author: TwitterUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var repost: TwitterStatus?
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var quote: TwitterStatus?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var replyTo: TwitterStatus?
    
    // one-to-many relationship
    @NSManaged public private(set) var repostFrom: Set<TwitterStatus>
    @NSManaged public private(set) var quoteFrom: Set<TwitterStatus>
    @NSManaged public private(set) var replyFrom: Set<TwitterStatus>
    
    // many-to-many relationship
    @NSManaged public private(set) var likeBy: Set<TwitterUser>
    @NSManaged public private(set) var repostBy: Set<TwitterUser>
    
}

extension TwitterStatus {
    // sourcery: autoUpdatableObject
    @objc public var attachments: [TwitterAttachment] {
        get {
            let keyPath = #keyPath(TwitterStatus.attachments)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let attachments = try JSONDecoder().decode([TwitterAttachment].self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(TwitterStatus.attachments)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject
    @objc public var location: TwitterLocation? {
        get {
            let keyPath = #keyPath(TwitterStatus.location)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return nil }
                let location = try JSONDecoder().decode(TwitterLocation.self, from: data)
                return location
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        set {
            let keyPath = #keyPath(TwitterStatus.location)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject
    @objc public var entities: TwitterEntity? {
        get {
            let keyPath = #keyPath(TwitterStatus.entities)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return nil }
                let entities = try JSONDecoder().decode(TwitterEntity.self, from: data)
                return entities
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        set {
            let keyPath = #keyPath(TwitterStatus.entities)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject
    @objc public var replySettings: TwitterReplySettings? {
        get {
            let keyPath = #keyPath(TwitterStatus.replySettings)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return nil }
                let replySettings = try JSONDecoder().decode(TwitterReplySettings.self, from: data)
                return replySettings
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        set {
            let keyPath = #keyPath(TwitterStatus.replySettings)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension TwitterStatus: FeedIndexable { }

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
    
    public static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterStatus.id), id)
    }
    
    public static func predicate(ids: [ID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterStatus.id), ids)
    }
    
}

// MARK: - AutoGenerateProperty
extension TwitterStatus: AutoGenerateProperty {
    // sourcery:inline:TwitterStatus.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let text: String
        public let likeCount: Int64
        public let replyCount: Int64
        public let repostCount: Int64
        public let quoteCount: Int64
        public let language: String?
        public let source: String?
        public let replyToStatusID: TwitterStatus.ID?
        public let replyToUserID: TwitterUser.ID?
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		id: ID,
    		text: String,
    		likeCount: Int64,
    		replyCount: Int64,
    		repostCount: Int64,
    		quoteCount: Int64,
    		language: String?,
    		source: String?,
    		replyToStatusID: TwitterStatus.ID?,
    		replyToUserID: TwitterUser.ID?,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.text = text
    		self.likeCount = likeCount
    		self.replyCount = replyCount
    		self.repostCount = repostCount
    		self.quoteCount = quoteCount
    		self.language = language
    		self.source = source
    		self.replyToStatusID = replyToStatusID
    		self.replyToUserID = replyToUserID
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.text = property.text
    	self.likeCount = property.likeCount
    	self.replyCount = property.replyCount
    	self.repostCount = property.repostCount
    	self.quoteCount = property.quoteCount
    	self.language = property.language
    	self.source = property.source
    	self.replyToStatusID = property.replyToStatusID
    	self.replyToUserID = property.replyToUserID
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(text: property.text)
    	update(likeCount: property.likeCount)
    	update(repostCount: property.repostCount)
    	update(source: property.source)
    	update(replyToStatusID: property.replyToStatusID)
    	update(replyToUserID: property.replyToUserID)
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
    	public let poll: TwitterPoll?
    	public let author: TwitterUser
    	public let repost: TwitterStatus?
    	public let quote: TwitterStatus?

    	public init(
    		poll: TwitterPoll?,
    		author: TwitterUser,
    		repost: TwitterStatus?,
    		quote: TwitterStatus?
    	) {
    		self.poll = poll
    		self.author = author
    		self.repost = repost
    		self.quote = quote
    	}
    }

    public func configure(relationship: Relationship) {
    	self.poll = relationship.poll
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
    public func update(likeCount: Int64) {
    	if self.likeCount != likeCount {
    		self.likeCount = likeCount
    	}
    }
    public func update(repostCount: Int64) {
    	if self.repostCount != repostCount {
    		self.repostCount = repostCount
    	}
    }
    public func update(source: String?) {
    	if self.source != source {
    		self.source = source
    	}
    }
    public func update(conversationID: TwitterStatus.ID?) {
    	if self.conversationID != conversationID {
    		self.conversationID = conversationID
    	}
    }
    public func update(replyToStatusID: TwitterStatus.ID?) {
    	if self.replyToStatusID != replyToStatusID {
    		self.replyToStatusID = replyToStatusID
    	}
    }
    public func update(replyToUserID: TwitterUser.ID?) {
    	if self.replyToUserID != replyToUserID {
    		self.replyToUserID = replyToUserID
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
    public func update(replyTo: TwitterStatus?) {
    	if self.replyTo != replyTo {
    		self.replyTo = replyTo
    	}
    }
    public func update(attachments: [TwitterAttachment]) {
    	if self.attachments != attachments {
    		self.attachments = attachments
    	}
    }
    public func update(location: TwitterLocation?) {
    	if self.location != location {
    		self.location = location
    	}
    }
    public func update(entities: TwitterEntity?) {
    	if self.entities != entities {
    		self.entities = entities
    	}
    }
    public func update(replySettings: TwitterReplySettings?) {
    	if self.replySettings != replySettings {
    		self.replySettings = replySettings
    	}
    }
    // sourcery:end
    
    public func update(replyCount: Int64) {
        if self.replyCount != replyCount {
            self.replyCount = replyCount
        }
    }
    
    public func update(quoteCount: Int64) {
        if self.quoteCount != quoteCount {
            self.quoteCount = quoteCount
        }
    }
    
    public func update(isRepost: Bool, by user: TwitterUser) {
        if isRepost {
            if !repostBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterStatus.repostBy)).add(user)
            }
        } else {
            if repostBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterStatus.repostBy)).remove(user)
            }
        }
    }
    
    public func update(isLike: Bool, by user: TwitterUser) {
        if isLike {
            if !likeBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterStatus.likeBy)).add(user)
            }
        } else {
            if likeBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterStatus.likeBy)).remove(user)
            }
        }
    }
}

extension TwitterStatus {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(TwitterStatus.feeds)).add(feed)
    }
    
    public func attach(poll: TwitterPoll) {
        guard self.poll == nil else { return }
        self.poll = poll
    }
}
