//
//  Tweet.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData
import TwitterAPI

final public class Tweet: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: UUID

    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var text: String
    @NSManaged public private(set) var createdAt: Date      // client required
    
    @NSManaged public private(set) var conversationID: String?
    @NSManaged public private(set) var inReplyToTweetID: ID?
    @NSManaged public private(set) var inReplyToUserID: String?
    @NSManaged public private(set) var lang: String?
    @NSManaged public private(set) var possiblySensitive: Bool
    @NSManaged public private(set) var source: String?
    
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    @NSManaged public private(set) var metrics: TweetMetrics?
    @NSManaged public private(set) var poll: TwitterPoll?
    @NSManaged public private(set) var place: TwitterPlace?
    @NSManaged public private(set) var withheld: TwitteWithheld?
    
    // many-to-one relationship
    @NSManaged public private(set) var retweet: Tweet?
    @NSManaged public private(set) var quote: Tweet?
    @NSManaged public private(set) var replyTo: Tweet?
    @NSManaged public private(set) var author: TwitterUser
    @NSManaged public private(set) var pinnedBy: TwitterUser    // same to author
        
    // one-to-many relationship
    @NSManaged public private(set) var retweetFrom: Set<Tweet>?
    @NSManaged public private(set) var quoteFrom: Set<Tweet>?
    @NSManaged public private(set) var replyFrom: Set<Tweet>?
    @NSManaged public private(set) var timelineIndexes: Set<TimelineIndex>?
    @NSManaged public private(set) var mentionTimelineIndexes: Set<MentionTimelineIndex>?
    @NSManaged public private(set) var media: Set<TwitterMedia>?
    
    // many-to-many relationship
    @NSManaged public private(set) var likeBy: Set<TwitterUser>?
    @NSManaged public private(set) var retweetBy: Set<TwitterUser>?
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        author: TwitterUser,
        media: [TwitterMedia]?,
        entities: TweetEntities?,
        metrics: TweetMetrics?,
        place: TwitterPlace?,
        retweet: Tweet?,
        quote: Tweet?,
        replyTo: Tweet?,
        timelineIndex: TimelineIndex?,
        likeBy: TwitterUser?,
        retweetBy: TwitterUser?
    ) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.updatedAt = property.networkDate
        
        tweet.id = property.id
        tweet.text = property.text
        tweet.createdAt = property.createdAt
        tweet.conversationID = property.conversationID
        tweet.inReplyToTweetID = property.inReplyToTweetID
        tweet.inReplyToUserID = property.inReplyToUserID
        tweet.lang = property.lang
        tweet.possiblySensitive = property.possiblySensitive
        tweet.source = property.source
        
        tweet.author = author
        tweet.entities = entities
        tweet.metrics = metrics
        tweet.place = place
        
        tweet.retweet = retweet
        tweet.quote = quote
        tweet.replyTo = replyTo
        
        if let timelineIndex = timelineIndex {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.timelineIndexes)).add(timelineIndex)
        }
        if let media = media {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.media)).addObjects(from: media)
        }
        if let likeBy = likeBy {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.likeBy)).add(likeBy)
        }
        if let retweetBy = retweetBy {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.retweetBy)).add(retweetBy)
        }
        
        return tweet
    }
    
    // always update scrub-able attribute
    public func update(place: TwitterPlace?) {
        self.place = place
    }

    // relationship
    public func setupEntitiesIfNeeds() {
        if entities == nil {
            entities = TweetEntities.insert(into: managedObjectContext!, urls: nil, mentions: nil)
        }
    }
    
    public func update(replyTo: Tweet?) {
        if self.replyTo != replyTo {
            self.replyTo = replyTo
        }
    }
    
    public func update(inReplyToTweetID: Tweet.ID?) {
        if self.inReplyToTweetID != inReplyToTweetID {
            self.inReplyToTweetID = inReplyToTweetID
        }
    }
    
    public func setupMetricsIfNeeds() {
        if metrics == nil {
            metrics = TweetMetrics.insert(
                into: managedObjectContext!,
                property: .init(likeCount: nil, quoteCount: nil, replyCount: nil, retweetCount: nil)
            )
        }
    }
    
    public func update(liked: Bool, twitterUser: TwitterUser) {
        if liked {
            if !(self.likeBy ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(Tweet.likeBy)).addObjects(from: [twitterUser])
            }
        } else {
            if (self.likeBy ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(Tweet.likeBy)).remove(twitterUser)
            }
        }
    }

    public func update(retweeted: Bool, twitterUser: TwitterUser) {
        if retweeted {
            if !(self.retweetBy ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(Tweet.retweetBy)).addObjects(from: [twitterUser])
            }
        } else {
            if (self.retweetBy ?? Set()).contains(twitterUser) {
                self.mutableSetValue(forKey: #keyPath(Tweet.retweetBy)).remove(twitterUser)
            }
        }
    }
    
    public func update(media: [TwitterMedia]?) {
        if let media = media, !media.isEmpty {
            self.mutableSetValue(forKey: #keyPath(Tweet.media)).removeAllObjects()
            self.mutableSetValue(forKey: #keyPath(Tweet.media)).addObjects(from: media)
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension Tweet {
    public struct Property: NetworkUpdatable {
        public let id: Tweet.ID
        public let text: String
        public let createdAt: Date
        
        public let conversationID: String?
        public let inReplyToTweetID: Tweet.ID?
        public let inReplyToUserID: String?
        public let lang: String?
        public let possiblySensitive: Bool
        public let source: String?
        
        // API required
        public let networkDate: Date
        
        public init(id: Tweet.ID, text: String, createdAt: Date, conversationID: String?, replyToTweetID: Tweet.ID?, inReplyToUserID: TwitterUser.ID?, lang: String?, possiblySensitive: Bool, source: String?, networkDate: Date) {
            self.id = id
            self.text = text
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&apos;", with: "'")
            self.createdAt = createdAt
            self.conversationID = conversationID
            self.inReplyToTweetID = replyToTweetID
            self.inReplyToUserID = inReplyToUserID
            self.lang = lang
            self.possiblySensitive = possiblySensitive
            self.source = source
            self.networkDate = networkDate
        }
    }
}

extension Tweet: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Tweet.createdAt, ascending: false)]
    }
}

extension Tweet {
    
    public static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Tweet.id), idStr)
    }
    
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Tweet.id), idStrs)
    }
    
}
