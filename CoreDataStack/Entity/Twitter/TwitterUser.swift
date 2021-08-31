//
//  TwitterUser.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreData

final public class TwitterUser: NSManagedObject {
    
    public typealias ID = String
    
    // @NSManaged public private(set) var identifier: UUID

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
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
//    @NSManaged public private(set) var pinnedTweet: Tweet?
//    @NSManaged public private(set) var entities: TwitterUserEntities?
//    @NSManaged public private(set) var metrics: TwitterUserMetrics?
//    @NSManaged public private(set) var withheld: TwitteWithheld?

    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?

    // one-to-many relationship
    @NSManaged public private(set) var statuses: Set<TwitterStatus>
//    @NSManaged public private(set) var inReplyFrom: Set<Tweet>
//    @NSManaged public private(set) var mentionIn: Set<TweetEntitiesMention>?

    // many-to-many relationship
    @NSManaged public private(set) var like: Set<Tweet>
    @NSManaged public private(set) var reposts: Set<Tweet>

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

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterUser {
        let object: TwitterUser = context.insertObject()
        object.configure(property: property)
        
//        if let followingBy = followingBy {
//            object.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).add(followingBy)
//        }
//        if let followRequestSentFrom = followRequestSentFrom {
//            object.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).add(followRequestSentFrom)
//        }
        
        return object
    }
    
    public func update(entitiesURLProperties: [TwitterUserEntitiesURL.Property]) {
//        guard let entities = entities else { return }
//        let oldURLs = Set((entities.urls ?? Set()).compactMap { $0.url })
//        let newURLs = Set(entitiesURLProperties.compactMap { $0.url })
//        if oldURLs != newURLs {
//            entities.mutableSetValue(forKey: #keyPath(TwitterUserEntities.urls)).removeAllObjects()
//            let urls = entitiesURLProperties.map { property in
//                TwitterUserEntitiesURL.insert(into: managedObjectContext!, property: property)
//            }
//            entities.mutableSetValue(forKey: #keyPath(TwitterUserEntities.urls)).addObjects(from: urls)
//        }
    }
    
    public func setupMetricsIfNeeds() {
//        if metrics == nil {
//            metrics = TwitterUserMetrics.insert(
//                into: managedObjectContext!,
//                property: .init(followersCount: nil, followingCount: nil, listedCount: nil, tweetCount: nil)
//            )
//        }
    }
    
    public func update(following: Bool, by: TwitterUser) {
        if following {
            if !(self.followingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).add(by)
            }
        } else {
            if (self.followingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).remove(by)
            }
        }
    }
    
    public func update(followRequestSent: Bool, from: TwitterUser) {
        if followRequestSent {
            if !(self.followRequestSentFrom ?? Set()).contains(from) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).add(from)
            }
        } else {
            if (self.followRequestSentFrom ?? Set()).contains(from) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).remove(from)
            }
        }
    }
    
    public func update(muting: Bool, by: TwitterUser) {
        if muting {
            if !(self.mutingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.mutingBy)).add(by)
            }
        } else {
            if (self.mutingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.mutingBy)).remove(by)
            }
        }
    }
    
    public func update(blocking: Bool, by: TwitterUser) {
        if blocking {
            if !(self.blockingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.blockingBy)).add(by)
            }
        } else {
            if (self.blockingBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.blockingBy)).remove(by)
            }
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

//extension TwitterUser {
//    public struct Property: NetworkUpdatable {
//        public let id: ID
//        public let name: String
//        public let username: String
//
//        public let bioDescription: String?
//        public let createdAt: Date?
//        public let location: String?
//        public let pinnedTweetID: Tweet.ID?
//        public let profileBannerURL: String?
//        public let profileImageURL: String?
//        public let protected: Bool
//        public let url: String?
//        public let verified: Bool
//
//        public var networkDate: Date
//
//        public init(id: TwitterUser.ID, name: String, username: String, bioDescription: String?, createdAt: Date?, location: String?, pinnedTweetID: Tweet.ID?, profileBannerURL: String?, profileImageURL: String?, protected: Bool, url: String?, verified: Bool, networkDate: Date) {
//            self.id = id
//            self.name = name
//            self.username = username
//            self.bioDescription = bioDescription?
//                .replacingOccurrences(of: "&amp;", with: "&")
//                .replacingOccurrences(of: "&lt;", with: "<")
//                .replacingOccurrences(of: "&gt;", with: ">")
//                .replacingOccurrences(of: "&quot;", with: "\"")
//                .replacingOccurrences(of: "&apos;", with: "'")
//            self.createdAt = createdAt
//            self.location = location
//            self.pinnedTweetID = pinnedTweetID
//            self.profileBannerURL = profileBannerURL
//            self.profileImageURL = profileImageURL
//            self.protected = protected
//            self.url = url
//            self.verified = verified
//            self.networkDate = networkDate
//        }
//    }
//}

extension TwitterUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUser.updatedAt, ascending: false)]
    }
}

extension TwitterUser {
    
    @available(*, deprecated, message: "")
    public static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.id), idStr)
    }
    
    public static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.id), id)
    }
    
    @available(*, deprecated, message: "")
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterUser.id), idStrs)
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
        public let  id: ID
        public let  name: String
        public let  username: String
        public let  bio: String?
        public let  createdAt: Date?
        public let  location: String?
        public let  profileImageURL: String?
        public let  protected: Bool
        public let  url: String?
        public let  verified: Bool
        public let  updatedAt: Date

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
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension TwitterUser: AutoGenerateRelationship {
    // sourcery:inline:TwitterUser.AutoUpdatableObject
    // sourcery:end
}

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
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}
