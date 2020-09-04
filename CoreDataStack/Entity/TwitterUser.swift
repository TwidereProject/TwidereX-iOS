//
//  TwitterUser.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreData

final public class TwitterUser: NSManagedObject {
    
    @NSManaged public private(set) var id: UUID

    @NSManaged public private(set) var idStr: String
    
    @NSManaged public private(set) var name: String?
    @NSManaged public private(set) var screenName: String?
    @NSManaged public private(set) var bioDescription: String?
    @NSManaged public private(set) var createdAt: Date?
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged public private(set) var followersCount: NSNumber?
    @NSManaged public private(set) var listedCount: NSNumber?
    @NSManaged public private(set) var favouritesCount: NSNumber?
    @NSManaged public private(set) var statusesCount: NSNumber?
    
    @NSManaged public private(set) var profileImageURL: String?
    @NSManaged public private(set) var profileImageURLHTTPS: String?
    @NSManaged public private(set) var profileBackgroundImageURL: String?
    @NSManaged public private(set) var profileBackgroundImageURLHTTPS: String?
    
    // one-to-many relationship
    @NSManaged public private(set) var tweets: Set<Tweet>?
}

extension TwitterUser {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> TwitterUser {
        let user: TwitterUser = context.insertObject()
        user.updatedAt = property.networkDate
        
        user.idStr = property.idStr
        user.name = property.name
        user.screenName = property.screenName
        user.bioDescription = property.bioDescription
        user.createdAt = property.createdAt
        user.followersCount = property.followersCount
        user.listedCount = property.listedCount
        user.favouritesCount = property.favouritesCount
        user.statusesCount = property.statusesCount
        user.profileImageURL = property.profileImageURL
        user.profileImageURLHTTPS = property.profileImageURLHTTPS
        user.profileBackgroundImageURL = property.profileBackgroundImageURL
        user.profileBackgroundImageURLHTTPS = property.profileBackgroundImageURLHTTPS
        return user
    }
    
    public func update(name: String) {
        if self.name != name {
            self.name = name
        }
    }
    public func update(screenName: String) {
        if self.screenName != screenName {
            self.screenName = screenName
        }
    }
    public func update(bioDescription: String) {
        if self.bioDescription != bioDescription {
            self.bioDescription = bioDescription
        }
    }
    
    public func update(followersCount: Int) {
        if self.followersCount != NSNumber(value: followersCount) {
            self.followersCount = NSNumber(value: followersCount)
        }
    }
    public func update(listedCount: Int) {
        if self.listedCount != NSNumber(value: listedCount) {
            self.listedCount = NSNumber(value: listedCount)
        }
    }
    public func update(favouritesCount: Int) {
        if self.favouritesCount != NSNumber(value: favouritesCount) {
            self.favouritesCount = NSNumber(value: favouritesCount)
        }
    }
    public func update(statusesCount: Int) {
        if self.statusesCount != NSNumber(value: statusesCount) {
            self.statusesCount = NSNumber(value: statusesCount)
        }
    }
    
    public func update(profileImageURL: String?) {
        if self.profileImageURL != profileImageURL {
            self.profileImageURL = profileImageURL
        }
    }
    public func update(profileImageURLHTTPS: String?) {
        if self.profileImageURLHTTPS != profileImageURLHTTPS {
            self.profileImageURLHTTPS = profileImageURLHTTPS
        }
    }
    public func update(profileBackgroundImageURL: String?) {
        if self.profileBackgroundImageURL != profileBackgroundImageURL {
            self.profileBackgroundImageURL = profileBackgroundImageURL
        }
    }
    public func update(profileBackgroundImageURLHTTPS: String?) {
        if self.profileBackgroundImageURLHTTPS != profileBackgroundImageURLHTTPS {
            self.profileBackgroundImageURLHTTPS = profileBackgroundImageURLHTTPS
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
}

extension TwitterUser {
    public struct Property: NetworkUpdatable {
        public let idStr: String
        
        public let name: String?
        public let screenName: String?
        public let bioDescription: String?
        public let createdAt: Date?
        
        public let followersCount: NSNumber?
        public let listedCount: NSNumber?
        public let favouritesCount: NSNumber?
        public let statusesCount: NSNumber?
        
        public let profileImageURL: String?
        public let profileImageURLHTTPS: String?
        public let profileBackgroundImageURL: String?
        public let profileBackgroundImageURLHTTPS: String?
        
        public var networkDate: Date
        
        public init(
            idStr: String,
            name: String?,
            screenName: String?,
            bioDescription: String?,
            createdAt: Date?,
            followersCount: NSNumber?,
            listedCount: NSNumber?,
            favouritesCount: NSNumber?,
            statusesCount: NSNumber?,
            profileImageURL: String?,
            profileImageURLHTTPS: String?,
            profileBackgroundImageURL: String?,
            profileBackgroundImageURLHTTPS: String?,
            networkDate: Date
        ) {
            self.idStr = idStr
            self.name = name
            self.screenName = screenName
            self.bioDescription = bioDescription
            self.createdAt = createdAt
            self.followersCount = followersCount
            self.listedCount = listedCount
            self.favouritesCount = favouritesCount
            self.statusesCount = statusesCount
            self.profileImageURL = profileImageURL
            self.profileImageURLHTTPS = profileImageURLHTTPS
            self.profileBackgroundImageURL = profileBackgroundImageURL
            self.profileBackgroundImageURLHTTPS = profileBackgroundImageURLHTTPS
            self.networkDate = networkDate
        }
    }
}

extension TwitterUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitterUser.updatedAt, ascending: false)]
    }
}

extension TwitterUser {
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterUser.idStr), idStrs)
    }
}
