//
//  MastodonNotificationSubscription.swift
//  
//
//  Created by MainasuK on 2022-7-14.
//

import Foundation
import CoreData

final public class MastodonNotificationSubscription: NSManagedObject {
    public typealias ID = String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var id: ID?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var domain: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var endpoint: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var serverKey: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var userToken: String?

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var isActive: Bool

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var follow: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var favourite: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var reblog: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var mention: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var poll: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var authentication: MastodonAuthentication?
    
}

extension MastodonNotificationSubscription {
    @NSManaged private var mentionPreference: Data?
    @NSManaged private var primitiveMentionPreferenceTransient: MentionPreference?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public private(set) var mentionPreferenceTransient: MentionPreference {
        get {
            let keyPath = #keyPath(mentionPreferenceTransient)
            willAccessValue(forKey: keyPath)
            let mentionPreference = primitiveMentionPreferenceTransient
            didAccessValue(forKey: keyPath)
            if let mentionPreference = mentionPreference {
                return mentionPreference
            } else {
                do {
                    let _data = self.mentionPreference
                    guard let data = _data, !data.isEmpty else {
                        primitiveMentionPreferenceTransient = MentionPreference()
                        return MentionPreference()
                    }
                    let mentionPreference = try JSONDecoder().decode(MentionPreference.self, from: data)
                    primitiveMentionPreferenceTransient = mentionPreference
                    return mentionPreference
                } catch {
                    assertionFailure(error.localizedDescription)
                    return MentionPreference()
                }
            }
        }
        set {
            let keyPath = #keyPath(mentionPreferenceTransient)
            do {
                let data = try JSONEncoder().encode(newValue)
                mentionPreference = data
                willChangeValue(forKey: keyPath)
                primitiveMentionPreferenceTransient = newValue
                didChangeValue(forKey: keyPath)
            } catch {
                assertionFailure()
            }
        }
    }
}

extension MastodonNotificationSubscription {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> MastodonNotificationSubscription {
        let object: MastodonNotificationSubscription = context.insertObject()
        object.configure(property: property)
        object.configure(relationship: relationship)
        return object
    }
    
}

extension MastodonNotificationSubscription: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonNotificationSubscription.createdAt, ascending: false)]
    }
}

extension MastodonNotificationSubscription {
    
    public static func predicate(userToken: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotificationSubscription.userToken), userToken)
    }

}

// MARK: - AutoGenerateProperty
extension MastodonNotificationSubscription: AutoGenerateProperty {
    // sourcery:inline:MastodonNotificationSubscription.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID?
        public let domain: String?
        public let endpoint: String?
        public let serverKey: String?
        public let userToken: String?
        public let isActive: Bool
        public let follow: Bool
        public let favourite: Bool
        public let reblog: Bool
        public let mention: Bool
        public let poll: Bool
        public let createdAt: Date
        public let updatedAt: Date
        public let mentionPreferenceTransient: MentionPreference

    	public init(
    		id: ID?,
    		domain: String?,
    		endpoint: String?,
    		serverKey: String?,
    		userToken: String?,
    		isActive: Bool,
    		follow: Bool,
    		favourite: Bool,
    		reblog: Bool,
    		mention: Bool,
    		poll: Bool,
    		createdAt: Date,
    		updatedAt: Date,
    		mentionPreferenceTransient: MentionPreference
    	) {
    		self.id = id
    		self.domain = domain
    		self.endpoint = endpoint
    		self.serverKey = serverKey
    		self.userToken = userToken
    		self.isActive = isActive
    		self.follow = follow
    		self.favourite = favourite
    		self.reblog = reblog
    		self.mention = mention
    		self.poll = poll
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.mentionPreferenceTransient = mentionPreferenceTransient
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.domain = property.domain
    	self.endpoint = property.endpoint
    	self.serverKey = property.serverKey
    	self.userToken = property.userToken
    	self.isActive = property.isActive
    	self.follow = property.follow
    	self.favourite = property.favourite
    	self.reblog = property.reblog
    	self.mention = property.mention
    	self.poll = property.poll
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.mentionPreferenceTransient = property.mentionPreferenceTransient
    }

    public func update(property: Property) {
    	update(id: property.id)
    	update(domain: property.domain)
    	update(endpoint: property.endpoint)
    	update(serverKey: property.serverKey)
    	update(userToken: property.userToken)
    	update(isActive: property.isActive)
    	update(follow: property.follow)
    	update(favourite: property.favourite)
    	update(reblog: property.reblog)
    	update(mention: property.mention)
    	update(poll: property.poll)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    	update(mentionPreferenceTransient: property.mentionPreferenceTransient)
    }

    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension MastodonNotificationSubscription: AutoGenerateRelationship {
    // sourcery:inline:MastodonNotificationSubscription.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let authentication: MastodonAuthentication?

    	public init(
    		authentication: MastodonAuthentication?
    	) {
    		self.authentication = authentication
    	}
    }

    public func configure(relationship: Relationship) {
    	self.authentication = relationship.authentication
    }

    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonNotificationSubscription: AutoUpdatableObject {
    // sourcery:inline:MastodonNotificationSubscription.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(id: ID?) {
    	if self.id != id {
    		self.id = id
    	}
    }
    public func update(domain: String?) {
    	if self.domain != domain {
    		self.domain = domain
    	}
    }
    public func update(endpoint: String?) {
    	if self.endpoint != endpoint {
    		self.endpoint = endpoint
    	}
    }
    public func update(serverKey: String?) {
    	if self.serverKey != serverKey {
    		self.serverKey = serverKey
    	}
    }
    public func update(userToken: String?) {
    	if self.userToken != userToken {
    		self.userToken = userToken
    	}
    }
    public func update(isActive: Bool) {
    	if self.isActive != isActive {
    		self.isActive = isActive
    	}
    }
    public func update(follow: Bool) {
    	if self.follow != follow {
    		self.follow = follow
    	}
    }
    public func update(favourite: Bool) {
    	if self.favourite != favourite {
    		self.favourite = favourite
    	}
    }
    public func update(reblog: Bool) {
    	if self.reblog != reblog {
    		self.reblog = reblog
    	}
    }
    public func update(mention: Bool) {
    	if self.mention != mention {
    		self.mention = mention
    	}
    }
    public func update(poll: Bool) {
    	if self.poll != poll {
    		self.poll = poll
    	}
    }
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(mentionPreferenceTransient: MentionPreference) {
    	if self.mentionPreferenceTransient != mentionPreferenceTransient {
    		self.mentionPreferenceTransient = mentionPreferenceTransient
    	}
    }

    // sourcery:end
}
