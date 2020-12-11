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
            id: entity.idStr,
            name: entity.name,
            username: entity.screenName,
            bioDescription: entity.userDescription,
            createdAt: entity.createdAt,
            location: entity.location,
            pinnedTweetID: nil,
            profileBannerURL: entity.profileBannerURL,
            profileImageURL: entity.profileImageURLHTTPS,
            protected: entity.protected ?? false,
            url: entity.url,
            verified: entity.verified ?? false,
            networkDate: networkDate
        )
    }
    
    init(entity: Twitter.Entity.V2.User, networkDate: Date) {
        self.init(
            id: entity.id,
            name: entity.name,
            username: entity.username,
            bioDescription: entity.description,
            createdAt: entity.createdAt,
            location: entity.location,
            pinnedTweetID: entity.pinnedTweetID,
            profileBannerURL: nil,
            profileImageURL: entity.profileImageURL,
            protected: entity.protected ?? false,
            url: entity.url,
            verified: entity.verified ?? false,
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
        guard let imageURLString = profileImageURL, var imageURL = URL(string: imageURLString) else { return nil }
        
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

extension TwitterUser {
    var displayBioDescription: String? {
        return bioDescription.flatMap { bioDescription in
            var bioDescription = bioDescription
            for url in entities?.urls ?? [] {
                guard let shortURL = url.url, let expandedURL = url.expandedURL else { continue }
                bioDescription = bioDescription.replacingOccurrences(of: shortURL, with: expandedURL)
            }
            return bioDescription
        }
    }
    
    var displayURL: String? {
        return url.flatMap { text in
            var text = text
            for url in entities?.urls ?? [] {
                guard let shortURL = url.url, let expandedURL = url.expandedURL else { continue }
                text = text.replacingOccurrences(of: shortURL, with: expandedURL)
            }
            return text
        }
    }
}

extension TwitterUser {
    
    public enum SizeKind: String {
        case small
        case medium
        case large
    }
    
    public func profileBannerURL(sizeKind: SizeKind) -> URL? {
        guard let urlString = self.profileBannerURL, let url = URL(string: urlString) else { return nil }
        let dimension: String = {
            switch sizeKind {
            case .small:    return "300x100"
            case .medium:   return "600x200"
            case .large:    return "1500x500"
            }
        }()
        return url.appendingPathComponent(dimension)
    }
}


extension String {
    mutating func deleteSuffix(_ suffix: String) {
        guard hasSuffix(suffix) else { return }
        removeLast(suffix.count)
    }
}
