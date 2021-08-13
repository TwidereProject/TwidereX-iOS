//
//  TwitterMediaMetrics.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TwitterMediaMetrics: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    /// int64
    @NSManaged public private(set) var viewCount: NSNumber?
    
    // one-to-one relationship
    @NSManaged public private(set) var media: TwitterMedia?
    
}

extension TwitterMediaMetrics {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
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
        return [NSSortDescriptor(keyPath: \TwitterMediaMetrics.createdAt, ascending: false)]
    }
}
