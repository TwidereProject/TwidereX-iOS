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
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var userID: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var screenName: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var consumerKey: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var consumerSecret: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var accessToken: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var accessTokenSecret: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var nonce: String

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var bearerAccessToken: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var bearerRefreshToken: String
    
    
    @NSManaged public private(set) var createdAt: Date
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var authenticationIndex: AuthenticationIndex
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var user: TwitterUser
    
}

extension TwitterAuthentication {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: #keyPath(TwitterAuthentication.identifier))
        
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(TwitterAuthentication.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(TwitterAuthentication.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> TwitterAuthentication {
        let object: TwitterAuthentication = context.insertObject()

        object.configure(property: property)
        object.configure(relationship: relationship)

        return object
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

// MARK: - AutoGenerateProperty
extension TwitterAuthentication: AutoGenerateProperty {
    // sourcery:inline:TwitterAuthentication.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let userID: String
        public let screenName: String
        public let consumerKey: String
        public let consumerSecret: String
        public let accessToken: String
        public let accessTokenSecret: String
        public let nonce: String
        public let bearerAccessToken: String
        public let bearerRefreshToken: String
        public let updatedAt: Date

    	public init(
    		userID: String,
    		screenName: String,
    		consumerKey: String,
    		consumerSecret: String,
    		accessToken: String,
    		accessTokenSecret: String,
    		nonce: String,
    		bearerAccessToken: String,
    		bearerRefreshToken: String,
    		updatedAt: Date
    	) {
    		self.userID = userID
    		self.screenName = screenName
    		self.consumerKey = consumerKey
    		self.consumerSecret = consumerSecret
    		self.accessToken = accessToken
    		self.accessTokenSecret = accessTokenSecret
    		self.nonce = nonce
    		self.bearerAccessToken = bearerAccessToken
    		self.bearerRefreshToken = bearerRefreshToken
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.userID = property.userID
    	self.screenName = property.screenName
    	self.consumerKey = property.consumerKey
    	self.consumerSecret = property.consumerSecret
    	self.accessToken = property.accessToken
    	self.accessTokenSecret = property.accessTokenSecret
    	self.nonce = property.nonce
    	self.bearerAccessToken = property.bearerAccessToken
    	self.bearerRefreshToken = property.bearerRefreshToken
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(screenName: property.screenName)
    	update(consumerKey: property.consumerKey)
    	update(consumerSecret: property.consumerSecret)
    	update(accessToken: property.accessToken)
    	update(accessTokenSecret: property.accessTokenSecret)
    	update(nonce: property.nonce)
    	update(bearerAccessToken: property.bearerAccessToken)
    	update(bearerRefreshToken: property.bearerRefreshToken)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension TwitterAuthentication: AutoGenerateRelationship {
    // sourcery:inline:TwitterAuthentication.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let authenticationIndex: AuthenticationIndex
    	public let user: TwitterUser

    	public init(
    		authenticationIndex: AuthenticationIndex,
    		user: TwitterUser
    	) {
    		self.authenticationIndex = authenticationIndex
    		self.user = user
    	}
    }

    public func configure(relationship: Relationship) {
    	self.authenticationIndex = relationship.authenticationIndex
    	self.user = relationship.user
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterAuthentication: AutoUpdatableObject {
    // sourcery:inline:TwitterAuthentication.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
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
    public func update(bearerAccessToken: String) {
    	if self.bearerAccessToken != bearerAccessToken {
    		self.bearerAccessToken = bearerAccessToken
    	}
    }
    public func update(bearerRefreshToken: String) {
    	if self.bearerRefreshToken != bearerRefreshToken {
    		self.bearerRefreshToken = bearerRefreshToken
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}
