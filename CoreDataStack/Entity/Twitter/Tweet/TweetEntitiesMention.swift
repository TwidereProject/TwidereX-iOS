//
//  TweetEntitiesMention.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TweetEntitiesMention: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var start: NSNumber?
    @NSManaged public private(set) var end: NSNumber?
    @NSManaged public private(set) var username: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    @NSManaged public private(set) var user: TwitterUser?
    
}

extension TweetEntitiesMention {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
}

extension TweetEntitiesMention {
    
}

extension TweetEntitiesMention: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesMention.identifier, ascending: false)]
    }
}
