//
//  TwitterUserMetrics.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterUserMetrics: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    /// Int64
    @NSManaged public private(set) var followersCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var followingCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var listedCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var tweetCount: NSNumber?
    
    // one-to-one relationship
    @NSManaged public private(set) var user: TwitterUser?
    
}

extension TwitterUserMetrics {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterUserMetrics {
        let metrics: TwitterUserMetrics = context.insertObject()
        metrics.followersCount = property.followersCount.flatMap { NSNumber(value: $0) }
        metrics.followingCount = property.followingCount.flatMap { NSNumber(value: $0) }
        metrics.listedCount = property.listedCount.flatMap { NSNumber(value: $0) }
        metrics.tweetCount = property.tweetCount.flatMap { NSNumber(value: $0) }
        return metrics
    }
    
    public func update(followersCount: Int?) {
        if self.followersCount?.intValue != followersCount {
            self.followersCount = followersCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(followingCount: Int?) {
        if self.followingCount?.intValue != followingCount {
            self.followingCount = followingCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(listedCount: Int?) {
        if self.listedCount?.intValue != listedCount {
            self.listedCount = listedCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(tweetCount: Int?) {
        if self.tweetCount?.intValue != tweetCount {
            self.tweetCount = tweetCount.flatMap { NSNumber(value: $0) }
        }
    }
}

extension TwitterUserMetrics {
    public struct Property {
        public let followersCount: Int?
        public let followingCount: Int?
        public let listedCount: Int?
        public let tweetCount: Int?
        
        public init(followersCount: Int?, followingCount: Int?, listedCount: Int?, tweetCount: Int?) {
            self.followersCount = followersCount
            self.followingCount = followingCount
            self.listedCount = listedCount
            self.tweetCount = tweetCount
        }
    }
}

extension TwitterUserMetrics: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUserMetrics.identifier, ascending: false)]
    }
}
