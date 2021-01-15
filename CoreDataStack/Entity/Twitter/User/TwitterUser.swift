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
    
    @NSManaged public private(set) var identifier: UUID

    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var username: String
    
    @NSManaged public private(set) var bioDescription: String?
    @NSManaged public private(set) var createdAt: Date?
    @NSManaged public private(set) var location: String?
    @NSManaged public private(set) var pinnedTweetID: Tweet.ID?
    @NSManaged public private(set) var profileBannerURL: String?
    @NSManaged public private(set) var profileImageURL: String?
    @NSManaged public private(set) var protected: Bool
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var verified: Bool
    
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var pinnedTweet: Tweet?
    @NSManaged public private(set) var entities: TwitterUserEntities?
    @NSManaged public private(set) var metrics: TwitterUserMetrics?
    @NSManaged public private(set) var withheld: TwitteWithheld?
    
    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?
    
    // one-to-many relationship
    @NSManaged public private(set) var tweets: Set<Tweet>?
    @NSManaged public private(set) var inReplyFrom: Set<Tweet>?
    @NSManaged public private(set) var mentionIn: Set<TweetEntitiesMention>?
    
    // many-to-many relationship
    @NSManaged public private(set) var like: Set<Tweet>?
    @NSManaged public private(set) var retweets: Set<Tweet>?
    
    @NSManaged public private(set) var following: Set<TwitterUser>?
    @NSManaged public private(set) var followingBy: Set<TwitterUser>?
    
    @NSManaged public private(set) var followRequestSent: Set<TwitterUser>?
    @NSManaged public private(set) var followRequestSentFrom: Set<TwitterUser>?
    
    @NSManaged public private(set) var muting: Set<TwitterUser>?
    @NSManaged public private(set) var mutingBy: Set<TwitterUser>?
    
    @NSManaged public private(set) var blocking: Set<TwitterUser>?
    @NSManaged public private(set) var blockingBy: Set<TwitterUser>?

}

extension TwitterUser {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        entities: TwitterUserEntities?,
        metrics: TwitterUserMetrics,
        followingBy: TwitterUser?,
        followRequestSentFrom: TwitterUser?
    ) -> TwitterUser {
        let user: TwitterUser = context.insertObject()
        user.updatedAt = property.networkDate
        
        user.id = property.id
        user.name = property.name
        user.username = property.username
        user.bioDescription = property.bioDescription
        user.createdAt = property.createdAt
        user.location = property.location
        user.pinnedTweetID = property.pinnedTweetID
        user.profileBannerURL = property.profileBannerURL
        user.profileImageURL = property.profileImageURL
        user.protected = property.protected
        user.url = property.url
        user.verified = property.verified
        
        user.entities = entities
        user.metrics = metrics
        
        if let followingBy = followingBy {
            user.mutableSetValue(forKey: #keyPath(TwitterUser.followingBy)).add(followingBy)
        }
        if let followRequestSentFrom = followRequestSentFrom {
            user.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).add(followRequestSentFrom)
        }
        
        return user
    }
    
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
    public func update(bioDescription: String) {
        if self.bioDescription != bioDescription {
            self.bioDescription = bioDescription
        }
    }
    public func update(createdAt: Date?) {
        if self.createdAt != createdAt {
            self.createdAt = createdAt
        }
    }
    public func update(url: String) {
        if self.url != url {
            self.url = url
        }
    }
    public func update(location: String) {
        if self.location != location {
            self.location = location
        }
    }
    public func update(pinnedTweetID: String) {
        if self.pinnedTweetID != pinnedTweetID {
            self.pinnedTweetID = pinnedTweetID
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
    
    // relationship
    public func setupEntitiesIfNeeds() {
        if entities == nil {
            entities = TwitterUserEntities.insert(into: managedObjectContext!, urls: nil)
        }
    }

    public func update(entitiesURLProperties: [TwitterUserEntitiesURL.Property]) {
        guard let entities = entities else { return }
        let oldURLs = Set((entities.urls ?? Set()).compactMap { $0.url })
        let newURLs = Set(entitiesURLProperties.compactMap { $0.url })
        if oldURLs != newURLs {
            entities.mutableSetValue(forKey: #keyPath(TwitterUserEntities.urls)).removeAllObjects()
            let urls = entitiesURLProperties.map { property in
                TwitterUserEntitiesURL.insert(into: managedObjectContext!, property: property)
            }
            entities.mutableSetValue(forKey: #keyPath(TwitterUserEntities.urls)).addObjects(from: urls)
        }
    }
    
    public func setupMetricsIfNeeds() {
        if metrics == nil {
            metrics = TwitterUserMetrics.insert(
                into: managedObjectContext!,
                property: .init(followersCount: nil, followingCount: nil, listedCount: nil, tweetCount: nil)
            )
        }
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

extension TwitterUser {
    public struct Property: NetworkUpdatable {
        public let id: ID
        public let name: String
        public let username: String
        
        public let bioDescription: String?
        public let createdAt: Date?
        public let location: String?
        public let pinnedTweetID: Tweet.ID?
        public let profileBannerURL: String?
        public let profileImageURL: String?
        public let protected: Bool
        public let url: String?
        public let verified: Bool
        
        public var networkDate: Date
        
        public init(id: TwitterUser.ID, name: String, username: String, bioDescription: String?, createdAt: Date?, location: String?, pinnedTweetID: Tweet.ID?, profileBannerURL: String?, profileImageURL: String?, protected: Bool, url: String?, verified: Bool, networkDate: Date) {
            self.id = id
            self.name = name
            self.username = username
            self.bioDescription = bioDescription?
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&apos;", with: "'")
            self.createdAt = createdAt
            self.location = location
            self.pinnedTweetID = pinnedTweetID
            self.profileBannerURL = profileBannerURL
            self.profileImageURL = profileImageURL
            self.protected = protected
            self.url = url
            self.verified = verified
            self.networkDate = networkDate
        }
    }
}

extension TwitterUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUser.updatedAt, ascending: false)]
    }
}

extension TwitterUser {
    
    public static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.id), idStr)
    }
    
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterUser.id), idStrs)
    }
    
    public static func predicate(username: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.username), username)
    }
    
}
