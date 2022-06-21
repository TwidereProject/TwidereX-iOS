//
//  TwitterPollOption.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import Foundation
import CoreData

public final class TwitterPollOption: NSManagedObject {
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var position: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var label: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votes: Int64
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var poll: TwitterPoll
    
}

extension TwitterPollOption {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> TwitterPollOption {
        let object: TwitterPollOption = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension TwitterPollOption: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterPollOption.createdAt, ascending: false)]
    }
}

// MARK: - AutoGenerateProperty
extension TwitterPollOption: AutoGenerateProperty {
    // sourcery:inline:TwitterPollOption.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let position: Int64
        public let label: String
        public let votes: Int64
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		position: Int64,
    		label: String,
    		votes: Int64,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.position = position
    		self.label = label
    		self.votes = votes
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.position = property.position
    	self.label = property.label
    	self.votes = property.votes
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(label: property.label)
    	update(votes: property.votes)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension TwitterPollOption: AutoUpdatableObject {
    // sourcery:inline:TwitterPollOption.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(label: String) {
    	if self.label != label {
    		self.label = label
    	}
    }
    public func update(votes: Int64) {
    	if self.votes != votes {
    		self.votes = votes
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}
