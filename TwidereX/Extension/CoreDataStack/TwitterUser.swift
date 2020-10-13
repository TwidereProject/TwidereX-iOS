//
//  TwitterUser.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreDataStack
import TwitterAPI

extension TwitterUser.Property {
    init(entity: Twitter.Entity.User, networkDate: Date) {
        self.init(
            idStr: entity.idStr,
            name: entity.name,
            screenName: entity.screenName,
            bioDescription: entity.userDescription,
            url: entity.url,
            location: entity.location,
            createdAt: entity.createdAt,
            protected: entity.protected ?? false,
            friendsCount: entity.friendsCount.flatMap { NSNumber(value: $0) },
            followersCount: entity.followersCount.flatMap { NSNumber(value: $0) },
            listedCount: entity.listedCount.flatMap { NSNumber(value: $0) },
            favouritesCount: entity.favouritesCount.flatMap { NSNumber(value: $0) },
            statusesCount: entity.statusesCount.flatMap { NSNumber(value: $0) },
            profileImageURLHTTPS: entity.profileImageURLHTTPS,
            profileBannerURL: entity.profileBannerURL,
            networkDate: networkDate
        )
    }
}

extension TwitterUser {
    public enum ProfileImageSize: String {
        case original
        case reasonablySmall = "reasonably_small"       // 128 * 128
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
