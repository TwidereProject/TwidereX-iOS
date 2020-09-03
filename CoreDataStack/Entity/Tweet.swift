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
    
    @NSManaged public private(set) var createdAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var timelineIndex: TimelineIndex
}

extension Tweet {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property, timelineIndex: TimelineIndex) -> Tweet {
        let tweet: Tweet = context.insertObject()
        tweet.timelineIndex = timelineIndex
        return tweet
    }
}

extension Tweet {
    public struct Property {
        let createdAt: Date
        
        public init(createdAt: Date) {
            self.createdAt = createdAt
        }
    }
}

extension Tweet: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Tweet.createdAt, ascending: false)]
    }
}
