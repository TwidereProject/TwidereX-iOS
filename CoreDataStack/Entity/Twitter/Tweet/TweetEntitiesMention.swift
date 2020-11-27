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
    @NSManaged public private(set) var userID: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    @NSManaged public private(set) var user: TwitterUser?
    
}

extension TweetEntitiesMention {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        user: TwitterUser?
    ) -> TweetEntitiesMention {
        let mention: TweetEntitiesMention = context.insertObject()
        
        mention.start = property.start
        mention.end = property.end
        mention.username = property.username
        mention.userID = property.userID
        
        mention.user = user
        
        return mention
    }
    
    public func update(entities: TweetEntities?) {
        if self.entities != entities {
            self.entities = entities
        }
    }
    
    public func update(user: TwitterUser?) {
        if self.user != user {
            self.user = user
        }
    }
    
}

extension TweetEntitiesMention {
    public struct Property {
        public var start: NSNumber?
        public var end: NSNumber?
        public var username: String?
        public var userID: String?
    
        public init(start: Int?, end: Int?, username: String?, userID: String?) {
            self.start = start.flatMap { NSNumber(value: $0) }
            self.end = end.flatMap { NSNumber(value: $0) }
            self.username = username
            self.userID = userID
        }
    }
}

extension TweetEntitiesMention: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesMention.identifier, ascending: false)]
    }
}

extension TweetEntitiesMention {
    public static func predicate(username: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TweetEntitiesMention.username), username)
    }
    
    public static func notHasUser() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(TweetEntitiesMention.user))
    }
}
