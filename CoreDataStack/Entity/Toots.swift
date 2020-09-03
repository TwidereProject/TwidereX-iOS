//
//  Toots.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class Toots: NSManagedObject {
    
    @NSManaged public private(set) var id: UUID
    
    @NSManaged public private(set) var createdAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var timelineIndex: TimelineIndex
    
}

extension Toots {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property, timelineIndex: TimelineIndex) -> Toots {
        let toots: Toots = context.insertObject()
        toots.timelineIndex = timelineIndex
        return toots
    }
}

extension Toots {
    public struct Property {
        let createdAt: Date
        
        public init(createdAt: Date) {
            self.createdAt = createdAt
        }
    }
}

extension Toots: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Toots.createdAt, ascending: false)]
    }
}
