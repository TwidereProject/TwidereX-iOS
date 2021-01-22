//
//  TweetEntitiesCashtag.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TweetEntitiesCashtag: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var start: NSNumber?
    @NSManaged public private(set) var end: NSNumber?
    @NSManaged public private(set) var tag: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    
}

extension TweetEntitiesCashtag {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
}

extension TweetEntitiesCashtag {
    
}

extension TweetEntitiesCashtag: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesCashtag.createdAt, ascending: false)]
    }
}
