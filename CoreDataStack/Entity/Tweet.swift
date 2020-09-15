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
    
    @NSManaged public private(set) var id: UUID
    
    @NSManaged public private(set) var idStr: String
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged public private(set) var text: String
    
    @NSManaged public private(set) var entitiesRaw: Data
    public var entities: Twitter.Entity.Entities {
        get {
            do {
                let value = try JSONDecoder().decode(Twitter.Entity.Entities.self, from: entitiesRaw)
                return value
            } catch {
                assertionFailure()
                return Twitter.Entity.Entities()
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                entitiesRaw = data
            } catch {
                assertionFailure()
                entitiesRaw = Data()
            }
        }
    }
    @NSManaged public private(set) var extendedEntitiesRaw: Data?
    public var extendedEntities: Twitter.Entity.ExtendedEntities? {
        get {
            guard let data = extendedEntitiesRaw else { return nil }
            do {
                let value = try JSONDecoder().decode(Twitter.Entity.ExtendedEntities.self, from: data)
                return value
            } catch {
                assertionFailure()
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                extendedEntitiesRaw = nil
                return
            }
            do {
                let data = try JSONEncoder().encode(newValue)
                extendedEntitiesRaw = data
            } catch {
                assertionFailure()
                extendedEntitiesRaw = nil
            }
        }
    }
    
    @NSManaged public private(set) var hasMore: Bool
    
    @NSManaged public private(set) var retweetCount: NSNumber?
    @NSManaged public private(set) var retweeted: Bool
    
    @NSManaged public private(set) var favoriteCount: NSNumber?
    @NSManaged public private(set) var favorited: Bool
    
    @NSManaged public private(set) var quotedStatusIDStr: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var timelineIndex: TimelineIndex?
    
    // many-to-one relationship
    @NSManaged public private(set) var user: TwitterUser
    @NSManaged public private(set) var retweet: Tweet?
    @NSManaged public private(set) var quote: Tweet?
    
    // one-to-many relationship
    @NSManaged public private(set) var retweetFrom: Set<Tweet>?
    @NSManaged public private(set) var quoteFrom: Set<Tweet>?
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property, retweet: Tweet?, quote: Tweet?, twitterUser: TwitterUser,  timelineIndex: TimelineIndex?) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.updatedAt = property.networkDate
        
        tweet.idStr = property.idStr
        tweet.createdAt = property.createdAt
        
        tweet.text = property.text
        tweet.entities = property.entities
        tweet.extendedEntities = property.extendedEntities
        
        tweet.timelineIndex = timelineIndex
        tweet.user = twitterUser
        tweet.retweet = retweet
        tweet.quote = quote
        return tweet
    }

    public func update(retweetCount: Int?) {
        let retweetCount = retweetCount.flatMap { NSNumber(value: $0) }
        if self.retweetCount != retweetCount {
            self.retweetCount = retweetCount
        }
    }
    
    public func update(retweeted: Bool) {
        if self.retweeted != retweeted {
            self.retweeted = retweeted
        }
    }
    
    public func update(retweet: Tweet?) {
        if self.retweet != retweet {
            self.retweet = retweet
        }
    }
    
    public func update(favoriteCount: Int?) {
        let favoriteCount = favoriteCount.flatMap { NSNumber(value: $0) }
        if self.favoriteCount != favoriteCount {
            self.favoriteCount = favoriteCount
        }
    }
    
    public func update(favorited: Bool) {
        if self.favorited != favorited {
            self.favorited = favorited
        }
    }
    
    public func update(timelineIndex: TimelineIndex?) {
        if self.timelineIndex != timelineIndex {
            self.timelineIndex = timelineIndex
        }
    }
    
    public func update(hasMore: Bool) {
        if self.hasMore != hasMore {
            self.hasMore = hasMore
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension Tweet {
    public struct Property: NetworkUpdatable {
        public let idStr: String
        public let createdAt: Date
        
        public let text: String
        public let entities: Twitter.Entity.Entities
        public let extendedEntities: Twitter.Entity.ExtendedEntities?
        
        public let retweetCount: Int?
        public let retweeted: Bool
        
        public let favoriteCount: Int?
        public let favorited: Bool
        
        public let quotedStatusIDStr: String?
        
        public let networkDate: Date
        
        public init(
            idStr: String,
            createdAt: Date,
            text: String,
            entities: Twitter.Entity.Entities,
            extendedEntities: Twitter.Entity.ExtendedEntities?,
            retweetCount: Int?,
            retweeted: Bool,
            favoriteCount: Int?,
            favorited: Bool,
            quotedStatusIDStr: String?,
            networkData: Date
        ) {
            self.idStr = idStr
            self.createdAt = createdAt
            
            self.text = text
            self.entities = entities
            self.extendedEntities = extendedEntities
            
            self.retweetCount = retweetCount
            self.retweeted = retweeted
            
            self.favoriteCount = favoriteCount
            self.favorited = favorited
            
            self.quotedStatusIDStr = quotedStatusIDStr
            
            self.networkDate = networkData
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
        return NSPredicate(format: "%K == %@", #keyPath(Tweet.idStr), idStr)
    }
    
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Tweet.idStr), idStrs)
    }
    
    public static func inTimeline() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Tweet.timelineIndex))
    }
    
    public static func notInTimeline() -> NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: inTimeline())
    }
    
}

extension Tweet {
    public var tweetID: Int {
        return Int(idStr)!
    }
}
