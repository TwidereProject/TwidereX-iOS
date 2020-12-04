//
//  TwitterUserEntities.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-11-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterUserEntities: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    // one-to-one relationship
    @NSManaged public private(set) var user: TwitterUser?
    
    // one-to-many relationship
    @NSManaged public private(set) var urls: Set<TwitterUserEntitiesURL>?
    
}

extension TwitterUserEntities {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        urls: [TwitterUserEntitiesURL]?
    ) -> TwitterUserEntities {
        let entities: TwitterUserEntities = context.insertObject()
        
        if let urls = urls {
            entities.mutableSetValue(forKey: #keyPath(TwitterUserEntities.urls)).addObjects(from: urls)
        }
        
        return entities
    }

}

extension TwitterUserEntities: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUserEntities.identifier, ascending: false)]
    }
}
