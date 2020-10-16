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
    
    public typealias TweetID = String
    
    @NSManaged public private(set) var id: UUID
    
    @NSManaged public private(set) var idStr: TweetID
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged public private(set) var text: String
    @NSManaged public private(set) var entitiesRaw: Data
    public private(set) var entities: Twitter.Entity.Entities {
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
    public private(set) var extendedEntities: Twitter.Entity.ExtendedEntities? {
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
    @NSManaged public private(set) var source: String?
    @NSManaged public private(set) var coordinatesRaw: Data?
    public private(set) var coordinates: Twitter.Entity.Coordinates? {
        get {
            guard let data = coordinatesRaw else { return nil }
            do {
                let value = try JSONDecoder().decode(Twitter.Entity.Coordinates.self, from: data)
                return value
            } catch {
                assertionFailure()
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                coordinatesRaw = nil
                return
            }
            do {
                let data = try JSONEncoder().encode(newValue)
                coordinatesRaw = data
            } catch {
                assertionFailure()
                coordinatesRaw = nil
            }
        }
    }
    @NSManaged public private(set) var placeRaw: Data?
    public private(set) var place: Twitter.Entity.Place? {
        get {
            guard let data = placeRaw else { return nil }
            do {
                let value = try JSONDecoder().decode(Twitter.Entity.Place.self, from: data)
                return value
            } catch {
                assertionFailure()
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                placeRaw = nil
                return
            }
            do {
                let data = try JSONEncoder().encode(newValue)
                placeRaw = data
            } catch {
                assertionFailure()
                placeRaw = nil
            }
        }
    }
    
    @NSManaged public private(set) var retweetCount: NSNumber?
    @NSManaged public private(set) var favoriteCount: NSNumber?
    
    @NSManaged public private(set) var quotedStatusIDStr: String?
    
    // V2
    @NSManaged public private(set) var conversationID: String?
        
    // many-to-one relationship
    @NSManaged public private(set) var user: TwitterUser
    @NSManaged public private(set) var retweet: Tweet?
    @NSManaged public private(set) var quote: Tweet?
    
    // one-to-many relationship
    @NSManaged public private(set) var retweetFrom: Set<Tweet>?
    @NSManaged public private(set) var quoteFrom: Set<Tweet>?
    @NSManaged public private(set) var timelineIndexes: Set<TimelineIndex>?
    
    // many-to-many relationship
    @NSManaged public private(set) var likeBy: Set<TwitterUser>?
    @NSManaged public private(set) var retweetBy: Set<TwitterUser>?
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        retweet: Tweet?,
        quote: Tweet?,
        twitterUser: TwitterUser,
        timelineIndex: TimelineIndex?,
        likeBy: TwitterUser?,
        retweetBy: TwitterUser?
    ) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.updatedAt = property.networkDate
        
        tweet.idStr = property.idStr
        tweet.createdAt = property.createdAt
        
        tweet.text = property.text
        tweet.entities = property.entities
        tweet.extendedEntities = property.extendedEntities
        tweet.source = property.source
        tweet.coordinates = property.coordinates
        tweet.place = property.place
        
        tweet.favoriteCount = property.favoriteCount.flatMap { NSNumber(value: $0) }
        tweet.retweetCount = property.retweetCount.flatMap { NSNumber(value: $0) }
        
        tweet.quotedStatusIDStr = property.quotedStatusIDStr
        
        // V2
        tweet.conversationID = property.conversationID
        
        timelineIndex.flatMap {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.timelineIndexes)).add($0)
        }
        tweet.user = twitterUser
        tweet.retweet = retweet
        tweet.quote = quote
        
        if let likeBy = likeBy {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.likeBy)).addObjects(from: [likeBy])
        }
        if let retweetBy = retweetBy {
            tweet.mutableSetValue(forKey: #keyPath(Tweet.retweetBy)).addObjects(from: [retweetBy])
        }
        
        return tweet
    }
    
    // always update scrub-able attribute
    public func update(coordinates: Twitter.Entity.Coordinates?) {
        self.coordinates = coordinates
    }
    
    // always update scrub-able attribute
    public func update(place: Twitter.Entity.Place?) {
        self.place = place
    }

    public func update(retweetCount: Int?) {
        let retweetCount = retweetCount.flatMap { NSNumber(value: $0) }
        if self.retweetCount != retweetCount {
            self.retweetCount = retweetCount
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
    
    public func update(quotedStatusIDStr: String?) {
        if self.quotedStatusIDStr != quotedStatusIDStr {
            self.quotedStatusIDStr = quotedStatusIDStr
        }
    }
    
    // relationship
    
    public func update(favorited: Bool, twitterUser: TwitterUser) {
        if favorited {
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
        public let source: String?
        public let coordinates: Twitter.Entity.Coordinates?
        public let place: Twitter.Entity.Place?
        
        public let retweetCount: Int?
        public let retweeted: Bool
        
        public let favoriteCount: Int?
        public let favorited: Bool
        
        public let quotedStatusIDStr: String?
        
        // V2
        public let conversationID: String?
        
        // API
        public let networkDate: Date
        
        public init(
            idStr: String,
            createdAt: Date,
            text: String,
            entities: Twitter.Entity.Entities,
            extendedEntities: Twitter.Entity.ExtendedEntities?,
            source: String?,
            coordinates: Twitter.Entity.Coordinates?,
            place: Twitter.Entity.Place?,
            retweetCount: Int?,
            retweeted: Bool,
            favoriteCount: Int?,
            favorited: Bool,
            quotedStatusIDStr: String?,
            conversationID: String?,
            networkData: Date
        ) {
            self.idStr = idStr
            self.createdAt = createdAt
            
            self.text = text
            self.entities = entities
            self.extendedEntities = extendedEntities
            self.source = source
            self.coordinates = coordinates
            self.place = place
            
            self.retweetCount = retweetCount
            self.retweeted = retweeted
            
            self.favoriteCount = favoriteCount
            self.favorited = favorited
            
            self.quotedStatusIDStr = quotedStatusIDStr
            
            self.conversationID = conversationID
            
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
    
//    public static func inTimeline(userID: String) -> NSPredicate {
//        return NSPredicate(format: "%K != nil", #keyPath(Tweet.timelineIndexes))
//    }
//    
//    public static func notInTimeline() -> NSPredicate {
//        return NSCompoundPredicate(notPredicateWithSubpredicate: inTimeline())
//    }
    
}
