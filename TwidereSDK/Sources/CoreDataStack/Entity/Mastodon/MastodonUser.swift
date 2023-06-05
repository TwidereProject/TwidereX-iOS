//
//  MastodonUser.swift
//  MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class MastodonUser: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var acct: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var username: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var displayName: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var note: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var avatar: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var avatarStatic: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var header: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var headerStatic: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var statusesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followingCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followersCount: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var locked: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var bot: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var suspended: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var mastodonAuthentication: MastodonAuthentication?
    // @NSManaged public private(set) var pinnedStatus: Status?
    // @NSManaged public private(set) var searchHistory: SearchHistory?
    
    // one-to-many relationship
    @NSManaged public private(set) var statuses: Set<MastodonStatus>
    @NSManaged public private(set) var notifications: Set<MastodonNotification>
    @NSManaged public private(set) var histories: Set<History>
    
    // many-to-many relationship
    @NSManaged public private(set) var like: Set<MastodonStatus>
    @NSManaged public private(set) var reposts: Set<MastodonStatus>
    // @NSManaged public private(set) var muted: Set<Status>?
    // @NSManaged public private(set) var bookmarked: Set<Status>?
    @NSManaged public private(set) var votePolls: Set<MastodonPoll>
    @NSManaged public private(set) var votePollOptions: Set<MastodonPollOption>
    
    // friendships
    @NSManaged public private(set) var following: Set<MastodonUser>
    @NSManaged public private(set) var followingBy: Set<MastodonUser>
    
    @NSManaged public private(set) var followRequestSent: Set<MastodonUser>
    @NSManaged public private(set) var followRequestSentFrom: Set<MastodonUser>
    
    @NSManaged public private(set) var muting: Set<MastodonUser>
    @NSManaged public private(set) var mutingBy: Set<MastodonUser>
    
    @NSManaged public private(set) var blocking: Set<MastodonUser>
    @NSManaged public private(set) var blockingBy: Set<MastodonUser>
    // @NSManaged public private(set) var endorsed: Set<MastodonUser>?
    // @NSManaged public private(set) var endorsedBy: Set<MastodonUser>?
    // @NSManaged public private(set) var domainBlocking: Set<MastodonUser>?
    // @NSManaged public private(set) var domainBlockingBy: Set<MastodonUser>?
    
    // sourcery:end
}

extension MastodonUser {
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
    
    @NSManaged private var fields: Data?
    @NSManaged private var primitiveFieldsTransient: [MastodonField]?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public private(set) var fieldsTransient: [MastodonField] {
        get {
            let keyPath = #keyPath(fieldsTransient)
            willAccessValue(forKey: keyPath)
            let fields = primitiveFieldsTransient
            didAccessValue(forKey: keyPath)
            if let fields = fields {
                return fields
            } else {
                do {
                    let _data = self.fields
                    guard let data = _data, !data.isEmpty else {
                        primitiveFieldsTransient = []
                        return []
                    }
                    let fields = try JSONDecoder().decode([MastodonField].self, from: data)
                    primitiveFieldsTransient = fields
                    return fields
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }
        }
        set {
            let keyPath = #keyPath(fieldsTransient)
            do {
                if newValue.isEmpty {
                    fields = nil
                } else {
                    let data = try JSONEncoder().encode(newValue)
                    fields = data
                }
                willChangeValue(forKey: keyPath)
                primitiveFieldsTransient = newValue
                didChangeValue(forKey: keyPath)
            } catch {
                assertionFailure()
            }
        }
    }
}

extension MastodonUser {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> MastodonUser {
        let object: MastodonUser = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension MastodonUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonUser.updatedAt, ascending: false)]
    }
}

extension MastodonUser {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.domain), domain)
    }
    
    static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.id), id)
    }
    
    public static func predicate(domain: String, id: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(id: id)
        ])
    }
    
    static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonUser.id), ids)
    }
    
    public static func predicate(domain: String, ids: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(ids: ids)
        ])
    }
    
    static func predicate(username: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.username), username)
    }
    
    public static func predicate(domain: String, username: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(username: username)
        ])
    }
    
}

// MARK: - AutoGenerateProperty
extension MastodonUser: AutoGenerateProperty {
    // sourcery:inline:MastodonUser.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let domain: String
        public let id: ID
        public let acct: String
        public let username: String
        public let displayName: String
        public let note: String?
        public let url: String?
        public let avatar: String?
        public let avatarStatic: String?
        public let header: String?
        public let headerStatic: String?
        public let statusesCount: Int64
        public let followingCount: Int64
        public let followersCount: Int64
        public let locked: Bool
        public let bot: Bool
        public let suspended: Bool
        public let createdAt: Date
        public let updatedAt: Date
        public let emojisTransient: [MastodonEmoji]
        public let fieldsTransient: [MastodonField]

    	public init(
    		domain: String,
    		id: ID,
    		acct: String,
    		username: String,
    		displayName: String,
    		note: String?,
    		url: String?,
    		avatar: String?,
    		avatarStatic: String?,
    		header: String?,
    		headerStatic: String?,
    		statusesCount: Int64,
    		followingCount: Int64,
    		followersCount: Int64,
    		locked: Bool,
    		bot: Bool,
    		suspended: Bool,
    		createdAt: Date,
    		updatedAt: Date,
    		emojisTransient: [MastodonEmoji],
    		fieldsTransient: [MastodonField]
    	) {
    		self.domain = domain
    		self.id = id
    		self.acct = acct
    		self.username = username
    		self.displayName = displayName
    		self.note = note
    		self.url = url
    		self.avatar = avatar
    		self.avatarStatic = avatarStatic
    		self.header = header
    		self.headerStatic = headerStatic
    		self.statusesCount = statusesCount
    		self.followingCount = followingCount
    		self.followersCount = followersCount
    		self.locked = locked
    		self.bot = bot
    		self.suspended = suspended
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.emojisTransient = emojisTransient
    		self.fieldsTransient = fieldsTransient
    	}
    }

    public func configure(property: Property) {
    	self.domain = property.domain
    	self.id = property.id
    	self.acct = property.acct
    	self.username = property.username
    	self.displayName = property.displayName
    	self.note = property.note
    	self.url = property.url
    	self.avatar = property.avatar
    	self.avatarStatic = property.avatarStatic
    	self.header = property.header
    	self.headerStatic = property.headerStatic
    	self.statusesCount = property.statusesCount
    	self.followingCount = property.followingCount
    	self.followersCount = property.followersCount
    	self.locked = property.locked
    	self.bot = property.bot
    	self.suspended = property.suspended
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.emojisTransient = property.emojisTransient
    	self.fieldsTransient = property.fieldsTransient
    }

    public func update(property: Property) {
    	update(acct: property.acct)
    	update(username: property.username)
    	update(displayName: property.displayName)
    	update(note: property.note)
    	update(url: property.url)
    	update(avatar: property.avatar)
    	update(avatarStatic: property.avatarStatic)
    	update(header: property.header)
    	update(headerStatic: property.headerStatic)
    	update(statusesCount: property.statusesCount)
    	update(followingCount: property.followingCount)
    	update(followersCount: property.followersCount)
    	update(locked: property.locked)
    	update(bot: property.bot)
    	update(suspended: property.suspended)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    	update(emojisTransient: property.emojisTransient)
    	update(fieldsTransient: property.fieldsTransient)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonUser: AutoUpdatableObject {
    // sourcery:inline:MastodonUser.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(acct: String) {
    	if self.acct != acct {
    		self.acct = acct
    	}
    }
    public func update(username: String) {
    	if self.username != username {
    		self.username = username
    	}
    }
    public func update(displayName: String) {
    	if self.displayName != displayName {
    		self.displayName = displayName
    	}
    }
    public func update(note: String?) {
    	if self.note != note {
    		self.note = note
    	}
    }
    public func update(url: String?) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(avatar: String?) {
    	if self.avatar != avatar {
    		self.avatar = avatar
    	}
    }
    public func update(avatarStatic: String?) {
    	if self.avatarStatic != avatarStatic {
    		self.avatarStatic = avatarStatic
    	}
    }
    public func update(header: String?) {
    	if self.header != header {
    		self.header = header
    	}
    }
    public func update(headerStatic: String?) {
    	if self.headerStatic != headerStatic {
    		self.headerStatic = headerStatic
    	}
    }
    public func update(statusesCount: Int64) {
    	if self.statusesCount != statusesCount {
    		self.statusesCount = statusesCount
    	}
    }
    public func update(followingCount: Int64) {
    	if self.followingCount != followingCount {
    		self.followingCount = followingCount
    	}
    }
    public func update(followersCount: Int64) {
    	if self.followersCount != followersCount {
    		self.followersCount = followersCount
    	}
    }
    public func update(locked: Bool) {
    	if self.locked != locked {
    		self.locked = locked
    	}
    }
    public func update(bot: Bool) {
    	if self.bot != bot {
    		self.bot = bot
    	}
    }
    public func update(suspended: Bool) {
    	if self.suspended != suspended {
    		self.suspended = suspended
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
    public func update(emojisTransient: [MastodonEmoji]) {
    	if self.emojisTransient != emojisTransient {
    		self.emojisTransient = emojisTransient
    	}
    }
    public func update(fieldsTransient: [MastodonField]) {
    	if self.fieldsTransient != fieldsTransient {
    		self.fieldsTransient = fieldsTransient
    	}
    }
    // sourcery:end
    
    public func update(isFollow: Bool, by user: MastodonUser) {
        if isFollow {
            if !followingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).add(user)
            }
        } else {
            if followingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).remove(user)
            }
        }
    }
    
    public func update(isFollowRequestSent: Bool, from user: MastodonUser) {
        if isFollowRequestSent {
            if !followRequestSentFrom.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestSentFrom)).add(user)
            }
        } else {
            if followRequestSentFrom.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestSentFrom)).remove(user)
            }
        }
    }
    
    public func update(isMute: Bool, by user: MastodonUser) {
        if isMute {
            if !mutingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).add(user)
            }
        } else {
            if mutingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).remove(user)
            }
        }
    }
    
    public func update(isBlock: Bool, by user: MastodonUser) {
        if isBlock {
            if !blockingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).add(user)
            }
        } else {
            if blockingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).remove(user)
            }
        }
    }
    
}

