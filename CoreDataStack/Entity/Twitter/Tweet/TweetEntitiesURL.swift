//
//  TweetEntitiesURL.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TweetEntitiesURL: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    
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
    }
    
}

extension TweetEntitiesURL {
    
}

extension TweetEntitiesURL: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesURL.identifier, ascending: false)]
    }
}
