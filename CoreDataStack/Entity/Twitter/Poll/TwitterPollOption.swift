//
//  TwitterPollOption.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterPollOption: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var label: String?
    // Int64
    @NSManaged public private(set) var position: NSNumber?
    // Int64
    @NSManaged public private(set) var votes: NSNumber?
    
    // one-to-one relationship
    @NSManaged public private(set) var poll: TwitterPoll?
    
}

extension TwitterPollOption {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
}

extension TwitterPollOption {
    
}

extension TwitterPollOption: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPollOption.createdAt, ascending: false)]
    }
}
