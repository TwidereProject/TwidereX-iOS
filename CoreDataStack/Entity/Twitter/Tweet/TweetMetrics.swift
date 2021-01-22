//
//  TweetMetrics.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TweetMetrics: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    /// Int64
    @NSManaged public private(set) var likeCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var quoteCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var replyCount: NSNumber?
    /// Int64
    @NSManaged public private(set) var retweetCount: NSNumber?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    
}

extension TweetMetrics {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TweetMetrics {
        let metrics: TweetMetrics = context.insertObject()
        metrics.likeCount = property.likeCount.flatMap { NSNumber(integerLiteral: $0)}
        metrics.quoteCount = property.quoteCount.flatMap { NSNumber(integerLiteral: $0)}
        metrics.replyCount = property.replyCount.flatMap { NSNumber(integerLiteral: $0)}
        metrics.retweetCount = property.retweetCount.flatMap { NSNumber(integerLiteral: $0)}
        return metrics
    }
    
    public func update(likeCount: Int?) {
        if self.likeCount?.intValue != likeCount {
            self.likeCount = likeCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(quoteCount: Int?) {
        if self.quoteCount?.intValue != quoteCount {
            self.quoteCount = quoteCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(replyCount: Int?) {
        if self.replyCount?.intValue != replyCount {
            self.replyCount = replyCount.flatMap { NSNumber(value: $0) }
        }
    }
    public func update(retweetCount: Int?) {
        if self.retweetCount?.intValue != retweetCount {
            self.retweetCount = retweetCount.flatMap { NSNumber(value: $0) }
        }
    }
    
}

extension TweetMetrics {
    public struct Property {
        public let likeCount: Int?
        public let quoteCount: Int?
        public let replyCount: Int?
        public let retweetCount: Int?
        
        public init(likeCount: Int?, quoteCount: Int?, replyCount: Int?, retweetCount: Int?) {
            self.likeCount = likeCount
            self.quoteCount = quoteCount
            self.replyCount = replyCount
            self.retweetCount = retweetCount
        }
    }
}

extension TweetMetrics: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntities.createdAt, ascending: false)]
    }
}
