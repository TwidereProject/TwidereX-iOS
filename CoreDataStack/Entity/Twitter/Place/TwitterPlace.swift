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

    @NSManaged public private(set) var country: String?
    @NSManaged public private(set) var countryCode: String?
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
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterPlace {
        let place: TwitterPlace = context.insertObject()
        
        place.id = property.id
        place.fullname = property.fullname
        place.country = property.country
        place.countryCode = property.countryCode
        place.geoJSON = nil
        place.name = property.name
        place.placeType = property.placeType
        place.id = property.id
        place.fullname = property.fullname
        
        return place
    }
}

extension TwitterPlace {
    public struct Property {
        public let id: ID
        public let fullname: String
        
        public let country: String?
        public let countryCode: String?
        //public let geo: Geo
        public let name: String?
        public let placeType: String?
        
        public init(id: TwitterPlace.ID, fullname: String, county: String?, countyCode: String?, name: String?, placeType: String?) {
            self.id = id
            self.fullname = fullname
            self.country = county
            self.countryCode = countyCode
            self.name = name
            self.placeType = placeType
        }
    }
}

extension TwitterPlace: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPlace.identifier, ascending: false)]
    }
}
