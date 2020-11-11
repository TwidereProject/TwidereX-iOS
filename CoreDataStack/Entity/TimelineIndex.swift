//
//  TimelineIndex.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class TimelineIndex: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var userID: String
    @NSManaged public private(set) var platformRaw: String
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var hasMore: Bool
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    @NSManaged public private(set) var toots: Toots?
}

extension TimelineIndex {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> TimelineIndex {
        let timelineIndex: TimelineIndex = context.insertObject()
        timelineIndex.userID = property.userID
        timelineIndex.platformRaw = property.platform.rawValue
        timelineIndex.createdAt = property.createdAt
        return timelineIndex
    }
    
    public func update(hasMore: Bool) {
        if self.hasMore != hasMore {
            self.hasMore = hasMore
        }
    }
    
}

extension TimelineIndex {
    public enum Platform: String {
        case twitter
        case mastodon
    }
    
    public struct Property {
        public let userID: String
        public let platform: Platform
        public let createdAt: Date
        
        public init(userID: String, platform: TimelineIndex.Platform, createdAt: Date) {
            self.userID = userID
            self.platform = platform
            self.createdAt = createdAt
        }
    }
}

extension TimelineIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TimelineIndex.createdAt, ascending: false)]
    }
}

extension TimelineIndex {
    
    public static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TimelineIndex.userID), userID)
    }
    
    public static func predicate(platform: Platform) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TimelineIndex.platformRaw), platform.rawValue)
    }
    
}
