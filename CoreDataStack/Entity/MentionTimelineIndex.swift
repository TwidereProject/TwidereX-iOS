//
//  MentionTimelineIndex.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class MentionTimelineIndex: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var userID: String
    @NSManaged public private(set) var platformRaw: String
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var hasMore: Bool
    
    @NSManaged public private(set) var deletedAt: Date?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    @NSManaged public private(set) var toots: Toots?
}

extension MentionTimelineIndex {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> MentionTimelineIndex {
        let timelineIndex: MentionTimelineIndex = context.insertObject()
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

extension MentionTimelineIndex {
    public enum Platform: String {
        case twitter
        case mastodon
    }
    
    public struct Property {
        public let userID: String
        public let platform: Platform
        public let createdAt: Date
        
        public init(userID: String, platform: MentionTimelineIndex.Platform, createdAt: Date) {
            self.userID = userID
            self.platform = platform
            self.createdAt = createdAt
        }
    }
}

extension MentionTimelineIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MentionTimelineIndex.createdAt, ascending: false)]
    }
}

extension MentionTimelineIndex {
    
    public static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MentionTimelineIndex.userID), userID)
    }
    
    public static func predicate(platform: Platform) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MentionTimelineIndex.platformRaw), platform.rawValue)
    }
    
}
