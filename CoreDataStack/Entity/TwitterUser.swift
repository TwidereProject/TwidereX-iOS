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
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var location: String?
    @NSManaged public private(set) var createdAt: Date?
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged public private(set) var followingRaw: NSNumber?
    public var following: Bool? {
        get {
            return followingRaw.flatMap { Bool(truncating: $0) }
        }
        set {
            followingRaw = newValue.flatMap { NSNumber(booleanLiteral: $0) }
        }
    }
    
    @NSManaged public private(set) var friendsCount: NSNumber?
    @NSManaged public private(set) var followersCount: NSNumber?
    @NSManaged public private(set) var listedCount: NSNumber?
    @NSManaged public private(set) var favouritesCount: NSNumber?
    @NSManaged public private(set) var statusesCount: NSNumber?
    
    @NSManaged public private(set) var profileImageURLHTTPS: String?
    @NSManaged public private(set) var profileBannerURL: String?
    
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
        user.url = property.url
        user.location = property.location
        user.createdAt = property.createdAt
        
        user.following = property.following
        
        user.friendsCount = property.friendsCount
        user.followersCount = property.followersCount
        user.listedCount = property.listedCount
        user.favouritesCount = property.favouritesCount
        user.statusesCount = property.statusesCount
        
        user.profileImageURLHTTPS = property.profileImageURLHTTPS
        user.profileBannerURL = property.profileBannerURL
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
    public func update(url: String) {
        if self.url != url {
            self.url = url
        }
    }
    public func update(location: String) {
        if self.location != location {
            self.location = location
        }
    }
    
    public func update(following: Bool?) {
        if self.following != following {
            self.following = following
        }
    }
    
    public func update(friendsCount: Int) {
        if self.friendsCount != NSNumber(value: friendsCount) {
            self.friendsCount = NSNumber(value: friendsCount)
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
    
    public func update(profileImageURLHTTPS: String?) {
        if self.profileImageURLHTTPS != profileImageURLHTTPS {
            self.profileImageURLHTTPS = profileImageURLHTTPS
        }
    }
    public func update(profileBannerURL: String?) {
        if self.profileBannerURL != profileBannerURL {
            self.profileBannerURL = profileBannerURL
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
        public let url: String?
        public let location: String?
        public let createdAt: Date?
        
        public let following: Bool?
        
        public let friendsCount: NSNumber?
        public let followersCount: NSNumber?
        public let listedCount: NSNumber?
        public let favouritesCount: NSNumber?
        public let statusesCount: NSNumber?
        
        public let profileImageURLHTTPS: String?
        public let profileBannerURL: String?
        
        public var networkDate: Date
        
        public init(
            idStr: String,
            name: String?,
            screenName: String?,
            bioDescription: String?,
            url: String?,
            location: String?,
            createdAt: Date?,
            following: Bool?,
            friendsCount: NSNumber?,
            followersCount: NSNumber?,
            listedCount: NSNumber?,
            favouritesCount: NSNumber?,
            statusesCount: NSNumber?,
            profileImageURLHTTPS: String?,
            profileBannerURL: String?,
            networkDate: Date
        ) {
            self.idStr = idStr
            self.name = name
            self.screenName = screenName
            self.bioDescription = bioDescription
            self.url = url
            self.location = location
            self.createdAt = createdAt
            self.following = following
            self.friendsCount = friendsCount
            self.followersCount = followersCount
            self.listedCount = listedCount
            self.favouritesCount = favouritesCount
            self.statusesCount = statusesCount
            self.profileImageURLHTTPS = profileImageURLHTTPS
            self.profileBannerURL = profileBannerURL
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
    public static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(TwitterUser.idStr), idStr)
    }
    
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(TwitterUser.idStr), idStrs)
    }
}

extension TwitterUser {
    public enum ProfileImageSize: String {
        case original
        case reasonablySmall = "reasonably_small"    // 128 * 128
        case bigger                                     // 73 * 73
        case normal                                     // 48 * 48
        case mini                                       // 24 * 24
        
        static var suffixedSizes: [ProfileImageSize] {
            return [.reasonablySmall, .bigger, .normal, .mini]
        }
    }
    
    /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/user-profile-images-and-banners
    public func avatarImageURL(size: ProfileImageSize = .reasonablySmall) -> URL? {
        guard let imageURLString = profileImageURLHTTPS, var imageURL = URL(string: imageURLString) else { return nil }
        
        let pathExtension = imageURL.pathExtension
        imageURL.deletePathExtension()
        
        var imageIdentifier = imageURL.lastPathComponent
        imageURL.deleteLastPathComponent()
        for suffixedSize in TwitterUser.ProfileImageSize.suffixedSizes {
            imageIdentifier.deleteSuffix("_\(suffixedSize.rawValue)")
        }
        
        switch size {
        case .original:
            imageURL.appendPathComponent(imageIdentifier)
        default:
            imageURL.appendPathComponent(imageIdentifier + "_" + size.rawValue)
        }
        
        imageURL.appendPathExtension(pathExtension)
        
        return imageURL
    }
    
}

extension String {
    mutating func deleteSuffix(_ suffix: String) {
        guard hasSuffix(suffix) else { return }
        removeLast(suffix.count)
    }
}