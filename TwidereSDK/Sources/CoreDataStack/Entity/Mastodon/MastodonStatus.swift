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
    @NSManaged public private(set) var likeCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var repostCount: Int64
    
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
    @NSManaged public private(set) var isMediaSensitive: Bool
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isContentSensitiveToggled: Bool
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isMediaSensitiveToggled: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var spoilerText: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var text: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var language: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var source: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyToStatusID: MastodonStatus.ID?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var replyToUserID: MastodonStatus.ID?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var poll: MastodonPoll?
    
    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>
    @NSManaged public private(set) var repostFrom: Set<MastodonStatus>
    @NSManaged public private(set) var notifications: Set<MastodonNotification>
    @NSManaged public private(set) var histories: Set<History>
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var author: MastodonUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var repost: MastodonStatus?
    
    // many-to-many relationship
    @NSManaged public private(set) var likeBy: Set<MastodonUser>
    @NSManaged public private(set) var repostBy: Set<MastodonUser>
    
}

extension MastodonStatus {
    @NSManaged private var attachments: Data?
    @NSManaged private var primitiveAttachmentsTransient: [MastodonAttachment]?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public private(set) var attachmentsTransient: [MastodonAttachment] {
        get {
            let keyPath = #keyPath(attachmentsTransient)
            willAccessValue(forKey: keyPath)
            let attachments = primitiveAttachmentsTransient
            didAccessValue(forKey: keyPath)
            if let attachments = attachments {
                return attachments
            } else {
                do {
                    let _data = self.attachments
                    guard let data = _data, !data.isEmpty else {
                        primitiveAttachmentsTransient = []
                        return []
                    }
                    let attachments = try JSONDecoder().decode([MastodonAttachment].self, from: data)
                    primitiveAttachmentsTransient = attachments
                    return attachments
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }
        }
        set {
            let keyPath = #keyPath(attachmentsTransient)
            do {
                if newValue.isEmpty {
                    attachments = nil
                } else {
                    let data = try JSONEncoder().encode(newValue)
                    attachments = data                    
                }
                willChangeValue(forKey: keyPath)
                primitiveAttachmentsTransient = newValue
                didChangeValue(forKey: keyPath)
            } catch {
                assertionFailure()
            }
        }
    }
    
    @NSManaged private var emojis: Data?
    @NSManaged private var primitiveEmojisTransient: [MastodonEmoji]?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public private(set) var emojisTransient: [MastodonEmoji] {
        get {
            let keyPath = #keyPath(emojisTransient)
            willAccessValue(forKey: keyPath)
            let emojis = primitiveEmojisTransient
            didAccessValue(forKey: keyPath)
            if let emojis = emojis {
                return emojis
            } else {
                do {
                    let _data = self.emojis
                    guard let data = _data, !data.isEmpty else {
                        primitiveEmojisTransient = []
                        return []
                    }
                    let emojis = try JSONDecoder().decode([MastodonEmoji].self, from: data)
                    primitiveEmojisTransient = emojis
                    return emojis
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }
        }
        set {
            let keyPath = #keyPath(emojisTransient)
            do {
                if newValue.isEmpty {
                    emojis = nil
                } else {
                    let data = try JSONEncoder().encode(newValue)
                    emojis = data
                }
                willChangeValue(forKey: keyPath)
                primitiveEmojisTransient = newValue
                didChangeValue(forKey: keyPath)
            } catch {
                assertionFailure()
            }
        }
    }
    
    @NSManaged private var mentions: Data?
    @NSManaged private var primitiveMentionsTransient: [MastodonMention]?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public private(set) var mentionsTransient: [MastodonMention] {
        get {
            let keyPath = #keyPath(mentionsTransient)
            willAccessValue(forKey: keyPath)
            let mentions = primitiveMentionsTransient
            didAccessValue(forKey: keyPath)
            if let mentions = mentions {
                return mentions
            } else {
                do {
                    let _data = self.mentions
                    guard let data = _data, !data.isEmpty else {
                        primitiveMentionsTransient = []
                        return []
                    }
                    let mentions = try JSONDecoder().decode([MastodonMention].self, from: data)
                    primitiveMentionsTransient = mentions
                    return mentions
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }
        }
        set {
            let keyPath = #keyPath(mentionsTransient)
            do {
                if newValue.isEmpty {
                    mentions = nil
                } else {
                    let data = try JSONEncoder().encode(newValue)
                    mentions = data
                }
                willChangeValue(forKey: keyPath)
                primitiveMentionsTransient = newValue
                didChangeValue(forKey: keyPath)
            } catch {
                assertionFailure()
            }
        }
    }
}

extension MastodonStatus: FeedIndexable { }

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
        public let id: ID
        public let domain: String
        public let uri: String
        public let content: String
        public let likeCount: Int64
        public let replyCount: Int64
        public let repostCount: Int64
        public let visibility: MastodonVisibility
        public let isMediaSensitive: Bool
        public let spoilerText: String?
        public let url: String?
        public let text: String?
        public let language: String?
        public let source: String?
        public let replyToStatusID: MastodonStatus.ID?
        public let replyToUserID: MastodonStatus.ID?
        public let createdAt: Date
        public let updatedAt: Date
        public let attachmentsTransient: [MastodonAttachment]
        public let emojisTransient: [MastodonEmoji]
        public let mentionsTransient: [MastodonMention]

    	public init(
    		id: ID,
    		domain: String,
    		uri: String,
    		content: String,
    		likeCount: Int64,
    		replyCount: Int64,
    		repostCount: Int64,
    		visibility: MastodonVisibility,
    		isMediaSensitive: Bool,
    		spoilerText: String?,
    		url: String?,
    		text: String?,
    		language: String?,
    		source: String?,
    		replyToStatusID: MastodonStatus.ID?,
    		replyToUserID: MastodonStatus.ID?,
    		createdAt: Date,
    		updatedAt: Date,
    		attachmentsTransient: [MastodonAttachment],
    		emojisTransient: [MastodonEmoji],
    		mentionsTransient: [MastodonMention]
    	) {
    		self.id = id
    		self.domain = domain
    		self.uri = uri
    		self.content = content
    		self.likeCount = likeCount
    		self.replyCount = replyCount
    		self.repostCount = repostCount
    		self.visibility = visibility
    		self.isMediaSensitive = isMediaSensitive
    		self.spoilerText = spoilerText
    		self.url = url
    		self.text = text
    		self.language = language
    		self.source = source
    		self.replyToStatusID = replyToStatusID
    		self.replyToUserID = replyToUserID
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.attachmentsTransient = attachmentsTransient
    		self.emojisTransient = emojisTransient
    		self.mentionsTransient = mentionsTransient
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
    	self.isMediaSensitive = property.isMediaSensitive
    	self.spoilerText = property.spoilerText
    	self.url = property.url
    	self.text = property.text
    	self.language = property.language
    	self.source = property.source
    	self.replyToStatusID = property.replyToStatusID
    	self.replyToUserID = property.replyToUserID
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.attachmentsTransient = property.attachmentsTransient
    	self.emojisTransient = property.emojisTransient
    	self.mentionsTransient = property.mentionsTransient
    }

    public func update(property: Property) {
    	update(content: property.content)
    	update(likeCount: property.likeCount)
    	update(replyCount: property.replyCount)
    	update(repostCount: property.repostCount)
    	update(visibility: property.visibility)
    	update(isMediaSensitive: property.isMediaSensitive)
    	update(spoilerText: property.spoilerText)
    	update(url: property.url)
    	update(text: property.text)
    	update(language: property.language)
    	update(source: property.source)
    	update(replyToStatusID: property.replyToStatusID)
    	update(replyToUserID: property.replyToUserID)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    	update(attachmentsTransient: property.attachmentsTransient)
    	update(emojisTransient: property.emojisTransient)
    	update(mentionsTransient: property.mentionsTransient)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonStatus: AutoGenerateRelationship {
    // sourcery:inline:MastodonStatus.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let poll: MastodonPoll?
    	public let author: MastodonUser
    	public let repost: MastodonStatus?

    	public init(
    		poll: MastodonPoll?,
    		author: MastodonUser,
    		repost: MastodonStatus?
    	) {
    		self.poll = poll
    		self.author = author
    		self.repost = repost
    	}
    }

    public func configure(relationship: Relationship) {
    	self.poll = relationship.poll
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
    public func update(likeCount: Int64) {
    	if self.likeCount != likeCount {
    		self.likeCount = likeCount
    	}
    }
    public func update(replyCount: Int64) {
    	if self.replyCount != replyCount {
    		self.replyCount = replyCount
    	}
    }
    public func update(repostCount: Int64) {
    	if self.repostCount != repostCount {
    		self.repostCount = repostCount
    	}
    }
    public func update(visibility: MastodonVisibility) {
    	if self.visibility != visibility {
    		self.visibility = visibility
    	}
    }
    public func update(isMediaSensitive: Bool) {
    	if self.isMediaSensitive != isMediaSensitive {
    		self.isMediaSensitive = isMediaSensitive
    	}
    }
    public func update(isContentSensitiveToggled: Bool) {
    	if self.isContentSensitiveToggled != isContentSensitiveToggled {
    		self.isContentSensitiveToggled = isContentSensitiveToggled
    	}
    }
    public func update(isMediaSensitiveToggled: Bool) {
    	if self.isMediaSensitiveToggled != isMediaSensitiveToggled {
    		self.isMediaSensitiveToggled = isMediaSensitiveToggled
    	}
    }
    public func update(spoilerText: String?) {
    	if self.spoilerText != spoilerText {
    		self.spoilerText = spoilerText
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
    public func update(source: String?) {
    	if self.source != source {
    		self.source = source
    	}
    }
    public func update(replyToStatusID: MastodonStatus.ID?) {
    	if self.replyToStatusID != replyToStatusID {
    		self.replyToStatusID = replyToStatusID
    	}
    }
    public func update(replyToUserID: MastodonStatus.ID?) {
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
    public func update(attachmentsTransient: [MastodonAttachment]) {
    	if self.attachmentsTransient != attachmentsTransient {
    		self.attachmentsTransient = attachmentsTransient
    	}
    }
    public func update(emojisTransient: [MastodonEmoji]) {
    	if self.emojisTransient != emojisTransient {
    		self.emojisTransient = emojisTransient
    	}
    }
    public func update(mentionsTransient: [MastodonMention]) {
    	if self.mentionsTransient != mentionsTransient {
    		self.mentionsTransient = mentionsTransient
    	}
    }
    // sourcery:end
    
    public func update(isRepost: Bool, by user: MastodonUser) {
        if isRepost {
            if !repostBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonStatus.repostBy)).add(user)
            }
        } else {
            if repostBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonStatus.repostBy)).remove(user)
            }
        }
    }
    
    public func update(isLike: Bool, by user: MastodonUser) {
        if isLike {
            if !likeBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonStatus.likeBy)).add(user)
            }
        } else {
            if likeBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonStatus.likeBy)).remove(user)
            }
        }
    }
}

extension MastodonStatus {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(MastodonStatus.feeds)).add(feed)
    }
}
