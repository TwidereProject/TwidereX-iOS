//
//  TwitterAuthentication.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreData

final public class TwitterAuthentication: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var userID: String
    @NSManaged public private(set) var screenName: String
    
    @NSManaged public private(set) var consumerKey: String
    @NSManaged public private(set) var consumerSecret: String
    
    @NSManaged public private(set) var accessToken: String
    @NSManaged public private(set) var accessTokenSecret: String
    
    @NSManaged public private(set) var nonce: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var authenticationIndex: AuthenticationIndex
    @NSManaged public private(set) var twitterUser: TwitterUser
    
}

extension TwitterAuthentication {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        let now = Date()
        createdAt = now
        updatedAt = now
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        authenticationIndex: AuthenticationIndex,
        twitterUser: TwitterUser
    ) -> TwitterAuthentication {
        let authentication: TwitterAuthentication = context.insertObject()
        
        authentication.userID = property.userID
        authentication.screenName = property.screenName
        
        authentication.consumerKey = property.consumerKey
        authentication.consumerSecret = property.consumerSecret
        
        authentication.accessToken = property.accessToken
        authentication.accessTokenSecret = property.accessTokenSecret
        
        authentication.nonce = property.nonce ?? ""
        
        authentication.authenticationIndex = authenticationIndex
        authentication.twitterUser = twitterUser
        
        return authentication
    }
    
    public func update(screenName: String) {
        if self.screenName != screenName {
            self.screenName = screenName
        }
    }
    
    public func update(consumerKey: String) {
        if self.consumerKey != consumerKey {
            self.consumerKey = consumerKey
        }
    }
    
    public func update(consumerSecret: String) {
        if self.consumerSecret != consumerSecret {
            self.consumerSecret = consumerSecret
        }
    }
    
    public func update(accessToken: String) {
        if self.accessToken != accessToken {
            self.accessToken = accessToken
        }
    }
    
    public func update(accessTokenSecret: String) {
        if self.accessTokenSecret != accessTokenSecret {
            self.accessTokenSecret = accessTokenSecret
        }
    }
    
    public func update(nonce: String) {
        if self.nonce != nonce {
            self.nonce = nonce
        }
    }
    
    public func update(twitterUser: TwitterUser) {
        if self.twitterUser != twitterUser {
            self.twitterUser = twitterUser
        }
    }
    
    public func update(updatedAt: Date) {
        if self.updatedAt != updatedAt {
            self.updatedAt = updatedAt
        }
    }
    
}

extension TwitterAuthentication {
    public struct Property {
        public let userID: String
        public let screenName: String
        public let consumerKey: String
        public let consumerSecret: String
        public let accessToken: String
        public let accessTokenSecret: String
        public let nonce: String?
        
        public init(userID: String, screenName: String, consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String, nonce: String? = nil) {
            self.userID = userID
            self.screenName = screenName
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.accessToken = accessToken
            self.accessTokenSecret = accessTokenSecret
            self.nonce = nonce
        }
    }
}

extension TwitterAuthentication: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterAuthentication.createdAt, ascending: false)]
    }
}

extension TwitterAuthentication {
    
    public static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterAuthentication.userID), userID)
    }
    
}
