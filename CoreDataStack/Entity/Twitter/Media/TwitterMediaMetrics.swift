//
//  TwitterMediaMetrics.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterMediaMetrics: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    
    /// int64
    @NSManaged public private(set) var viewCount: NSNumber?
    
    // one-to-one relationship
    @NSManaged public private(set) var media: TwitterMedia?
    
}

extension TwitterMediaMetrics {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterMediaMetrics {
        let metrics: TwitterMediaMetrics = context.insertObject()
        metrics.viewCount = property.viewCount
        return metrics
    }
    
}

extension TwitterMediaMetrics {
    public struct Property {
        public let viewCount: NSNumber?

        public init(viewCount: Int?) {
            self.viewCount = viewCount.flatMap { NSNumber(value: $0) }
        }
    }
}

extension TwitterMediaMetrics: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterMediaMetrics.identifier, ascending: false)]
    }
}
