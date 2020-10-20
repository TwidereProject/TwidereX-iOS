//
//  TwitterPlace.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitterPlace: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var fullname: String
    
    // TODO:
    // containedWithin

    @NSManaged public private(set) var county: String?
    @NSManaged public private(set) var countyCode: String?
    @NSManaged public private(set) var geoJSON: Data?
    // TODO: public private(set) var geo: Twitter.Entity.Geo { }
    @NSManaged public private(set) var name: String?
    @NSManaged public private(set) var placeType: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    
}

extension TwitterPlace {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    
}

extension TwitterPlace {
    
}

extension TwitterPlace: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPlace.identifier, ascending: false)]
    }
}
