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
    
    // one-to-one relationship
    @NSManaged public private(set) var timelineIndex: TimelineIndex
    
    // many-to-one relationship
    @NSManaged public private(set) var user: TwitterUser
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property, timelineIndex: TimelineIndex, twitterUser: TwitterUser) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.updatedAt = property.networkDate
        
        tweet.idStr = property.idStr
        tweet.createdAt = property.createdAt
        tweet.text = property.text
        
        tweet.timelineIndex = timelineIndex
        tweet.user = twitterUser
        return tweet
    }
    
    public func update(text: String) {
        if self.text != text {
            self.text = text
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
}
