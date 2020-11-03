//
//  Toots.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class Toots: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    
    // one-to-many relationship
    @NSManaged public private(set) var timelineIndexes: Set<TimelineIndex>?
    @NSManaged public private(set) var mentionTimelineIndexes: Set<MentionTimelineIndex>?
}

extension Toots {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    // @discardableResult
    // public static func insert(into context: NSManagedObjectContext, property: Property, timelineIndex: TimelineIndex) -> Toots {
    //     let toots: Toots = context.insertObject()
    //     toots.updatedAt = property.networkDate
    //     // TODO:
    //     return toots
    // }
}

extension Toots {
    public struct Property: NetworkUpdatable {
        public let createdAt: Date
        public let networkDate: Date
        
        public init(createdAt: Date, networkDate: Date) {
            self.createdAt = createdAt
            self.networkDate = networkDate
        }
    }
}

extension Toots: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Toots.createdAt, ascending: false)]
    }
}
