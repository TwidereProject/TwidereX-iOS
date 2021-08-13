//
//  TweetEntitiesURL.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TweetEntitiesURL: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var start: NSNumber?
    @NSManaged public private(set) var end: NSNumber?
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var expandedURL: String?
    @NSManaged public private(set) var displayURL: String?
    @NSManaged public private(set) var unwoundURL: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    
}

extension TweetEntitiesURL {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TweetEntitiesURL {
        let url: TweetEntitiesURL = context.insertObject()
        
        url.start = property.start
        url.end = property.end
        url.url = property.url
        url.expandedURL = property.expandedURL
        url.displayURL = property.displayURL
        url.unwoundURL = property.unwoundURL
        
        return url
    }
    
}

extension TweetEntitiesURL {
    public struct Property: NetworkUpdatable {
        public var start: NSNumber?
        public var end: NSNumber?
        public var url: String?
        public var expandedURL: String?
        public var displayURL: String?
        public var unwoundURL: String?
        
        // API required
        public let networkDate: Date

        public init(start: Int? = nil, end: Int? = nil, url: String? = nil, expandedURL: String? = nil, displayURL: String? = nil, unwoundURL: String? = nil, networkDate: Date) {
            self.start = start.flatMap { NSNumber(value: $0) }
            self.end = end.flatMap { NSNumber(value: $0) }
            self.url = url
            self.expandedURL = expandedURL
            self.displayURL = displayURL
            self.unwoundURL = unwoundURL
            self.networkDate = networkDate
        }
    }
}

extension TweetEntitiesURL: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesURL.createdAt, ascending: false)]
    }
}
