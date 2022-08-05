//
//  TwitterUser.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreData

public final class TwitterUser: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var name: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var username: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var bio: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var location: String?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var profileBannerURL: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var profileImageURL: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var protected: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var verified: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var statusesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followingCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followersCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var listedCount: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
//    @NSManaged public private(set) var pinnedTweet: Tweet?

    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?

    // one-to-many relationship
    @NSManaged public private(set) var statuses: Set<TwitterStatus>
    @NSManaged public private(set) var savedSearches: Set<TwitterSavedSearch>
    @NSManaged public private(set) var ownedLists: Set<TwitterList>
    @NSManaged public private(set) var histories: Set<History>
    
    // many-to-many relationship
    @NSManaged public private(set) var like: Set<TwitterStatus>
    @NSManaged public private(set) var reposts: Set<TwitterStatus>

    @NSManaged public private(set) var following: Set<TwitterUser>
    @NSManaged public private(set) var followingBy: Set<TwitterUser>

    @NSManaged public private(set) var followRequestSent: Set<TwitterUser>
    @NSManaged public private(set) var followRequestSentFrom: Set<TwitterUser>

    @NSManaged public private(set) var muting: Set<TwitterUser>
    @NSManaged public private(set) var mutingBy: Set<TwitterUser>

    @NSManaged public private(set) var blocking: Set<TwitterUser>
    @NSManaged public private(set) var blockingBy: Set<TwitterUser>

    // sourcery:end
}

extension TwitterUser {
    // sourcery: autoUpdatableObject
    @objc public var bioEntities: TwitterEntity? {
        get {
            let keyPath = #keyPath(TwitterUser.bioEntities)
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
            let keyPath = #keyPath(TwitterUser.bioEntities)
            willChangeValue(forKey: keyPath)
            if let newValue = newValue {
                let data = try? JSONEncoder().encode(newValue)
                setPrimitiveValue(data, forKey: keyPath)
            } else {
                setPrimitiveValue(nil, forKey: keyPath)
            }
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject
    @objc public var urlEntities: TwitterEntity? {
        get {
            let keyPath = #keyPath(TwitterUser.urlEntities)
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
            let keyPath = #keyPath(TwitterUser.urlEntities)
            willChangeValue(forKey: keyPath)
            if let newValue = newValue {
                let data = try? JSONEncoder().encode(newValue)
                setPrimitiveValue(data, forKey: keyPath)
            } else {
                setPrimitiveValue(nil, forKey: keyPath)
            }
            didChangeValue(forKey: keyPath)
        }
    }
}

extension TwitterUser {

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterUser {
        let object: TwitterUser = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension TwitterUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUser.updatedAt, ascending: false)]
    }
}

extension TwitterUser {
        
    public static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.id), id)
    }

    public static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterUser.id), ids)
    }
    
    public static func predicate(username: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.username), username)
    }
    
}

// MARK: - AutoGenerateProperty
extension TwitterUser: AutoGenerateProperty {
    // sourcery:inline:TwitterUser.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let name: String
        public let username: String
        public let bio: String?
        public let createdAt: Date?
        public let location: String?
        public let profileImageURL: String?
        public let protected: Bool
        public let url: String?
        public let verified: Bool
        public let statusesCount: Int64
        public let followingCount: Int64
        public let followersCount: Int64
        public let listedCount: Int64
        public let updatedAt: Date

    	public init(
    		id: ID,
    		name: String,
    		username: String,
    		bio: String?,
    		createdAt: Date?,
    		location: String?,
    		profileImageURL: String?,
    		protected: Bool,
    		url: String?,
    		verified: Bool,
    		statusesCount: Int64,
    		followingCount: Int64,
    		followersCount: Int64,
    		listedCount: Int64,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.name = name
    		self.username = username
    		self.bio = bio
    		self.createdAt = createdAt
    		self.location = location
    		self.profileImageURL = profileImageURL
    		self.protected = protected
    		self.url = url
    		self.verified = verified
    		self.statusesCount = statusesCount
    		self.followingCount = followingCount
    		self.followersCount = followersCount
    		self.listedCount = listedCount
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.name = property.name
    	self.username = property.username
    	self.bio = property.bio
    	self.createdAt = property.createdAt
    	self.location = property.location
    	self.profileImageURL = property.profileImageURL
    	self.protected = property.protected
    	self.url = property.url
    	self.verified = property.verified
    	self.statusesCount = property.statusesCount
    	self.followingCount = property.followingCount
    	self.followersCount = property.followersCount
    	self.listedCount = property.listedCount
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(name: property.name)
    	update(username: property.username)
    	update(bio: property.bio)
    	update(createdAt: property.createdAt)
    	update(location: property.location)
    	update(profileImageURL: property.profileImageURL)
    	update(protected: property.protected)
    	update(url: property.url)
    	update(verified: property.verified)
    	update(statusesCount: property.statusesCount)
    	update(followingCount: property.followingCount)
    	update(followersCount: property.followersCount)
    	update(listedCount: property.listedCount)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
//extension TwitterUser: AutoGenerateRelationship {
//    // sourcery:inline:TwitterUser.AutoUpdatableObject
//    // sourcery:end
//}

// MARK: - AutoUpdatableObject
extension TwitterUser: AutoUpdatableObject {
    // sourcery:inline:TwitterUser.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(name: String) {
    	if self.name != name {
    		self.name = name
    	}
    }
    public func update(username: String) {
    	if self.username != username {
    		self.username = username
    	}
    }
    public func update(bio: String?) {
    	if self.bio != bio {
    		self.bio = bio
    	}
    }
    public func update(createdAt: Date?) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(location: String?) {
    	if self.location != location {
    		self.location = location
    	}
    }
    public func update(profileBannerURL: String?) {
    	if self.profileBannerURL != profileBannerURL {
    		self.profileBannerURL = profileBannerURL
    	}
    }
    public func update(profileImageURL: String?) {
    	if self.profileImageURL != profileImageURL {
    		self.profileImageURL = profileImageURL
    	}
    }
    public func update(protected: Bool) {
    	if self.protected != protected {
    		self.protected = protected
    	}
    }
    public func update(url: String?) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(verified: Bool) {
    	if self.verified != verified {
    		self.verified = verified
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
    public func update(listedCount: Int64) {
    	if self.listedCount != listedCount {
    		self.listedCount = listedCount
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(bioEntities: TwitterEntity?) {
    	if self.bioEntities != bioEntities {
    		self.bioEntities = bioEntities
    	}
    }
    public func update(urlEntities: TwitterEntity?) {
    	if self.urlEntities != urlEntities {
    		self.urlEntities = urlEntities
    	}
    }
    // sourcery:end
    
    public func update(isFollow: Bool, by user: TwitterUser) {
        if isFollow {
            if !followingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).add(user)
            }
        } else {
            if followingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).remove(user)
            }
        }
    }
    
    public func update(isFollowRequestSent: Bool, from user: TwitterUser) {
        if isFollowRequestSent {
            if !followRequestSentFrom.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).add(user)
            }
        } else {
            if followRequestSentFrom.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).remove(user)
            }
        }
    }
    
    public func update(isMute: Bool, by user: TwitterUser) {
        if isMute {
            if !mutingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.mutingBy)).add(user)
            }
        } else {
            if mutingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.mutingBy)).remove(user)
            }
        }
    }
    
    public func update(isBlock: Bool, by user: TwitterUser) {
        if isBlock {
            if !blockingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.blockingBy)).add(user)
            }
        } else {
            if blockingBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.blockingBy)).remove(user)
            }
        }
    }

}
