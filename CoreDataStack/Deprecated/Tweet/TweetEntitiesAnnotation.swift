//
//  TweetEntitiesAnnotation.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterSDK

final public class TweetEntitiesAnnotation: NSManagedObject {
        
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var start: NSNumber?
    @NSManaged public private(set) var end: NSNumber?
    @NSManaged public private(set) var type: String?
    /// double
    @NSManaged public private(set) var probability: NSNumber?
    @NSManaged public private(set) var normalizedText: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var entities: TweetEntities?
    
}

extension TweetEntitiesAnnotation {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
}

extension TweetEntitiesAnnotation {

}

extension TweetEntitiesAnnotation: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TweetEntitiesAnnotation.createdAt, ascending: false)]
    }
}
