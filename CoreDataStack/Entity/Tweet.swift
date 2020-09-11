//
//  Tweet.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class Tweet: NSManagedObject {
    
    @NSManaged public private(set) var id: UUID
    
    @NSManaged public private(set) var idStr: String
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var text: String
    @NSManaged public private(set) var hasMore: Bool
    
    // one-to-one relationship
    @NSManaged public private(set) var timelineIndex: TimelineIndex?
    
    // many-to-one relationship
    @NSManaged public private(set) var user: TwitterUser
    @NSManaged public private(set) var retweet: Tweet?
    
    // one-to-many relationship
    @NSManaged public private(set) var retweetFrom: Set<Tweet>?
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property, retweet: Tweet?, twitterUser: TwitterUser,  timelineIndex: TimelineIndex?) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.updatedAt = property.networkDate
        
        tweet.idStr = property.idStr
        tweet.createdAt = property.createdAt
        tweet.text = property.text
        
        tweet.retweet = retweet
        tweet.user = twitterUser
        tweet.timelineIndex = timelineIndex
        return tweet
    }
    
    public func update(text: String) {
        if self.text != text {
            self.text = text
        }
    }
    
    public func update(hasMore: Bool) {
        if self.hasMore != hasMore {
            self.hasMore = hasMore
        }
    }
    
    public func update(timelineIndex: TimelineIndex?) {
        if self.timelineIndex != timelineIndex {
            self.timelineIndex = timelineIndex
        }
    }
    
    public func update(retweet: Tweet?) {
        if self.retweet != retweet {
            self.retweet = retweet
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
        
        public let networkDate: Date
        
        public init(idStr: String, createdAt: Date, text: String, networkData: Date) {
            self.idStr = idStr
            self.createdAt = createdAt
            self.text = text
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
