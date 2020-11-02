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
    @NSManaged public private(set) var metrics: TwitterUserMetrics?
    @NSManaged public private(set) var withheld: TwitteWithheld?
    
    // one-to-many relationship
    @NSManaged public private(set) var tweets: Set<Tweet>?
    @NSManaged public private(set) var inReplyFrom: Set<Tweet>?
    @NSManaged public private(set) var mentionIn: Set<TweetEntitiesMention>?
    
    // many-to-many relationship
    @NSManaged public private(set) var like: Set<Tweet>?
    @NSManaged public private(set) var retweets: Set<Tweet>?
    
    @NSManaged public private(set) var following: Set<TwitterUser>?
    @NSManaged public private(set) var followingFrom: Set<TwitterUser>?
    
    @NSManaged public private(set) var followRequestSent: Set<TwitterUser>?
    @NSManaged public private(set) var followRequestSentFrom: Set<TwitterUser>?
    
    @NSManaged public private(set) var followedBy: Set<TwitterUser>?
    @NSManaged public private(set) var followedByFrom: Set<TwitterUser>?

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
        metrics: TwitterUserMetrics,
        following: TwitterUser?,
        followRequestSent: TwitterUser?
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
        
        user.metrics = metrics
        
        if let following = following {
            user.mutableSetValue(forKey: #keyPath(TwitterUser.following)).addObjects(from: [following])
        }
        if let followRequestSent = followRequestSent {
            user.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSent)).addObjects(from: [followRequestSent])
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
    
//    public func update(friendsCount: Int) {
//        if self.friendsCount != NSNumber(value: friendsCount) {
//            self.friendsCount = NSNumber(value: friendsCount)
//        }
//    }
//    public func update(followersCount: Int) {
//        if self.followersCount != NSNumber(value: followersCount) {
//            self.followersCount = NSNumber(value: followersCount)
//        }
//    }
//    public func update(listedCount: Int) {
//        if self.listedCount != NSNumber(value: listedCount) {
//            self.listedCount = NSNumber(value: listedCount)
//        }
//    }
//    public func update(favouritesCount: Int) {
//        if self.favouritesCount != NSNumber(value: favouritesCount) {
//            self.favouritesCount = NSNumber(value: favouritesCount)
//        }
//    }
//    public func update(statusesCount: Int) {
//        if self.statusesCount != NSNumber(value: statusesCount) {
//            self.statusesCount = NSNumber(value: statusesCount)
//        }
//    }
    
    
    // relationship
    
    public func setupMetricsIfNeeds() {
        if metrics == nil {
            metrics = TwitterUserMetrics.insert(
                into: managedObjectContext!,
                property: .init(followersCount: nil, followingCount: nil, listedCount: nil, tweetCount: nil)
            )
        }
    }
    
    public func update(following: Bool, twitterUser: TwitterUser) {
        if following {
            if !(self.followingFrom ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingFrom)).add(twitterUser)
            }
        } else {
            if (self.followingFrom ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followingFrom)).remove(twitterUser)
            }
        }
    }
    
    public func update(followRequestSent: Bool, twitterUser: TwitterUser) {
        if followRequestSent {
            if !(self.followRequestSentFrom ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).add(twitterUser)
            }
        } else {
            if (self.followRequestSentFrom ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(TwitterUser.followRequestSentFrom)).remove(twitterUser)
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
            self.bioDescription = bioDescription
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
}
