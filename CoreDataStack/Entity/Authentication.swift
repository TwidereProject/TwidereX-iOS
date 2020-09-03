//
//  Authentication.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class Authentication: NSManagedObject {
    
    @NSManaged public private(set) var id: UUID
    
    @NSManaged public private(set) var userID: String
    @NSManaged public private(set) var screenName: String
    
    @NSManaged public private(set) var consumerKey: String
    @NSManaged public private(set) var consumerSecret: String
    
    @NSManaged public private(set) var accessToken: String
    @NSManaged public private(set) var accessTokenSecret: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
}

extension Authentication {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        let now = Date()
        createdAt = now
        updatedAt = now
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> Authentication {
        let authentication: Authentication = context.insertObject()
        authentication.userID = property.userID
        authentication.screenName = property.screenName
        authentication.consumerKey = property.consumerKey
        authentication.consumerSecret = property.consumerSecret
        authentication.accessToken = property.accessToken
        authentication.accessTokenSecret = property.accessTokenSecret
        authentication.userID = property.userID
        authentication.screenName = property.screenName
        return authentication
    }
}

extension Authentication {
    public struct Property {
        public let userID: String
        public let screenName: String
        public let consumerKey: String
        public let consumerSecret: String
        public let accessToken: String
        public let accessTokenSecret: String
        
        public init(userID: String, screenName: String, consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
            self.userID = userID
            self.screenName = screenName
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.accessToken = accessToken
            self.accessTokenSecret = accessTokenSecret
        }
    }
}

extension Authentication: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Authentication.createdAt, ascending: false)]
    }
}
