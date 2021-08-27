//
//  TweetEntities.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TweetEntities: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    // one-to-many relationship
    @NSManaged public private(set) var annotations: Set<TweetEntitiesAnnotation>?
    @NSManaged public private(set) var cashtags: Set<TweetEntitiesCashtag>?
    @NSManaged public private(set) var hashtags: Set<TweetEntitiesHashtag>?
    @NSManaged public private(set) var mentions: Set<TweetEntitiesMention>?
    @NSManaged public private(set) var urls: Set<TweetEntitiesURL>?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    
}

extension TweetEntities {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        urls: [TweetEntitiesURL]?,
        mentions: [TweetEntitiesMention]?
    ) -> TweetEntities {
        let entities: TweetEntities = context.insertObject()
        
        if let urls = urls {
            entities.mutableSetValue(forKey: #keyPath(TweetEntities.urls)).addObjects(from: urls)
        }
        if let mentions = mentions {
            entities.mutableSetValue(forKey: #keyPath(TweetEntities.mentions)).addObjects(from: mentions)
        }
        
        return entities
    }
    
}

extension TweetEntities: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntities.createdAt, ascending: false)]
    }
}
