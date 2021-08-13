//
//  TwitterPoll.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TwitterPoll: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var id: ID
    
    /// Int64
    @NSManaged public private(set) var durationMinutes: NSNumber?
    @NSManaged public private(set) var endDatetime: Date?
    @NSManaged public private(set) var votingStatus: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    @NSManaged public private(set) var options: Set<TwitterPollOption>?
    
}

extension TwitterPoll {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
}

extension TwitterPoll {
    
}

extension TwitterPoll: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPoll.createdAt, ascending: false)]
    }
}
