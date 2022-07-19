//
//  MastodonAuthentication.swift
//  MastodonAuthentication
//
//  Created by Cirno MainasuK on 2021-8-17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class MastodonAuthentication: NSManagedObject {
    
    public typealias ID = UUID
    
    @NSManaged public private(set) var identifier: ID
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var userID: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var appAccessToken: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var userAccessToken: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var clientID: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var clientSecret: String
    
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var authenticationIndex: AuthenticationIndex
    @NSManaged public private(set) var user: MastodonUser
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var notificationSubscription: MastodonNotificationSubscription?

}

extension MastodonAuthentication {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: #keyPath(MastodonAuthentication.identifier))
        
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthentication.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthentication.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        authenticationIndex: AuthenticationIndex,
        mastodonUser: MastodonUser
    ) -> MastodonAuthentication {
        let object: MastodonAuthentication = context.insertObject()
        
        object.configure(property: property)
        
        object.authenticationIndex = authenticationIndex
        object.user = mastodonUser
        
        return object
    }

}

extension MastodonAuthentication: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonAuthentication.createdAt, ascending: false)]
    }
}

extension MastodonAuthentication {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.domain), domain)
    }
    
    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.userID), userID)
    }
    
    public static func predicate(domain: String, userID: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonAuthentication.predicate(domain: domain),
            MastodonAuthentication.predicate(userID: userID)
        ])
    }
    
    public static func predicate(userAccessToken: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.userAccessToken), userAccessToken)
    }
    
}

// MARK: - AutoGenerateProperty
extension MastodonAuthentication: AutoGenerateProperty {
    // sourcery:inline:MastodonAuthentication.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let domain: String
        public let userID: String
        public let appAccessToken: String
        public let userAccessToken: String
        public let clientID: String
        public let clientSecret: String
        public let updatedAt: Date

    	public init(
    		domain: String,
    		userID: String,
    		appAccessToken: String,
    		userAccessToken: String,
    		clientID: String,
    		clientSecret: String,
    		updatedAt: Date
    	) {
    		self.domain = domain
    		self.userID = userID
    		self.appAccessToken = appAccessToken
    		self.userAccessToken = userAccessToken
    		self.clientID = clientID
    		self.clientSecret = clientSecret
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.domain = property.domain
    	self.userID = property.userID
    	self.appAccessToken = property.appAccessToken
    	self.userAccessToken = property.userAccessToken
    	self.clientID = property.clientID
    	self.clientSecret = property.clientSecret
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(appAccessToken: property.appAccessToken)
    	update(userAccessToken: property.userAccessToken)
    	update(clientID: property.clientID)
    	update(clientSecret: property.clientSecret)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonAuthentication: AutoUpdatableObject {
    // sourcery:inline:MastodonAuthentication.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(appAccessToken: String) {
    	if self.appAccessToken != appAccessToken {
    		self.appAccessToken = appAccessToken
    	}
    }
    public func update(userAccessToken: String) {
    	if self.userAccessToken != userAccessToken {
    		self.userAccessToken = userAccessToken
    	}
    }
    public func update(clientID: String) {
    	if self.clientID != clientID {
    		self.clientID = clientID
    	}
    }
    public func update(clientSecret: String) {
    	if self.clientSecret != clientSecret {
    		self.clientSecret = clientSecret
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(notificationSubscription: MastodonNotificationSubscription?) {
    	if self.notificationSubscription != notificationSubscription {
    		self.notificationSubscription = notificationSubscription
    	}
    }
    // sourcery:end
}
