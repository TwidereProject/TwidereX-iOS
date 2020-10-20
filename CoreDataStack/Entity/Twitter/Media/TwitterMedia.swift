//
//  TwitterMedia.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterMedia: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var index: NSNumber
    
    @NSManaged public private(set) var mediaKey: ID
    @NSManaged public private(set) var type: String
    
    /// int64
    @NSManaged public private(set) var height: NSNumber?
    /// int64
    @NSManaged public private(set) var weight: NSNumber?
    /// int64
    @NSManaged public private(set) var durationMS: NSNumber?
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var previewImageURL: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    @NSManaged public private(set) var metrics: TwitterMediaMetrics?
    
}

extension TwitterMedia {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        metrics: TwitterMediaMetrics
    ) -> TwitterMediaMetrics {
        let media: TwitterMedia = context.insertObject()
        
        media.index = property.index
        media.mediaKey = property.mediaKey
        media.type = property.type
        media.height = property.height
        media.weight = property.weight
        media.durationMS = property.durationMS
        media.url = property.url
        media.previewImageURL = property.previewImageURL

        media.metrics = metrics
        
        return metrics
    }
    
}

extension TwitterMedia {
    public struct Property {
        public let index: NSNumber
        public let mediaKey: ID
        public let type: String
        
        public let height: NSNumber?
        public let weight: NSNumber?
        public let durationMS: NSNumber?
        public let url: String?
        public let previewImageURL: String?
        
        public init(index: Int, mediaKey: TwitterMedia.ID, type: String, height: Int?, weight: Int?, durationMS: Int?, url: String?, previewImageURL: String?) {
            self.index = NSNumber(value: index)
            self.mediaKey = mediaKey
            self.type = type
            self.height = height.flatMap { NSNumber(value: $0) }
            self.weight = weight.flatMap { NSNumber(value: $0) }
            self.durationMS = durationMS.flatMap { NSNumber(value: $0) }
            self.url = url
            self.previewImageURL = previewImageURL
        }
    }
}

extension TwitterMedia: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterMedia.identifier, ascending: false)]
    }
}
