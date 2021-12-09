//
//  MastodonPollOption.swift
//  
//
//  Created by MainasuK on 2021-12-9.
//

import Foundation
import CoreData

public final class MastodonPollOption: NSManagedObject {
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var index: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var title: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votesCount: Int64
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    @NSManaged public private(set) var poll: MastodonPoll
    
    // many-to-many relationship
    @NSManaged public private(set) var voteBy: Set<MastodonUser>
    
}

extension MastodonPollOption {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> MastodonPollOption {
        let object: MastodonPollOption = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension MastodonPollOption: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonPollOption.createdAt, ascending: false)]
    }
}

// MARK: - AutoGenerateProperty
extension MastodonPollOption: AutoGenerateProperty {
    // sourcery:inline:MastodonPollOption.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let  index: Int64
        public let  title: String
        public let  votesCount: Int64
        public let  createdAt: Date
        public let  updatedAt: Date

    	public init(
    		index: Int64,
    		title: String,
    		votesCount: Int64,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.index = index
    		self.title = title
    		self.votesCount = votesCount
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.index = property.index
    	self.title = property.title
    	self.votesCount = property.votesCount
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(title: property.title)
    	update(votesCount: property.votesCount)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonPollOption: AutoUpdatableObject {
    // sourcery:inline:MastodonPollOption.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(title: String) {
    	if self.title != title {
    		self.title = title
    	}
    }
    public func update(votesCount: Int64) {
    	if self.votesCount != votesCount {
    		self.votesCount = votesCount
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
    
    public func update(isVote: Bool, by user: MastodonUser) {
        if isVote {
            if !voteBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonPollOption.voteBy)).add(user)
            }
        } else {
            if voteBy.contains(user) {
                self.mutableSetValue(forKey: #keyPath(MastodonPollOption.voteBy)).remove(user)
            }
        }
    }
}
