//
//  TwitterMedia.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TwitterMedia: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var index: NSNumber
    
    @NSManaged public private(set) var id: ID?          // preserved for v1 usage
    @NSManaged public private(set) var mediaKey: ID     // v2
    @NSManaged public private(set) var type: String
    
    /// int64
    @NSManaged public private(set) var height: NSNumber?
    /// int64
    @NSManaged public private(set) var width: NSNumber?
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
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        metrics: TwitterMediaMetrics?
    ) -> TwitterMedia {
        let media: TwitterMedia = context.insertObject()
        
        media.index = property.index
        media.id = property.id
        media.mediaKey = property.mediaKey
        media.type = property.type
        media.height = property.height
        media.width = property.width
        media.durationMS = property.durationMS
        media.url = property.url
        media.previewImageURL = property.previewImageURL

        media.metrics = metrics
        
        return media
    }
    
    public func update(url: String?) {
        if self.url != url {
            self.url = url
        }
    }
    
}

extension TwitterMedia {
    public struct Property {
        public let index: NSNumber
        public let id: ID?
        public let mediaKey: ID
        public let type: String
        
        public let height: NSNumber?
        public let width: NSNumber?
        public let durationMS: NSNumber?
        public let url: String?
        public let previewImageURL: String?
        
        public init(index: Int, id: TwitterMedia.ID?, mediaKey: TwitterMedia.ID, type: String, height: Int?, width: Int?, durationMS: Int?, url: String?, previewImageURL: String?) {
            self.index = NSNumber(value: index)
            self.id = id
            self.mediaKey = mediaKey
            self.type = type
            self.height = height.flatMap { NSNumber(value: $0) }
            self.width = width.flatMap { NSNumber(value: $0) }
            self.durationMS = durationMS.flatMap { NSNumber(value: $0) }
            self.url = url
            self.previewImageURL = previewImageURL
        }
    }
}

extension TwitterMedia: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterMedia.createdAt, ascending: false)]
    }
}
