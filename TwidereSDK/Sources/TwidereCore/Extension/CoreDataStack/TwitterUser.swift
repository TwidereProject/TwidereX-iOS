//
//  TwitterUser.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MetaTextKit
import TwitterMeta

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

extension TwitterUser {
    public var bioURLEntities: [TwitterContent.URLEntity] {
        let results = bioEntities?.urls?.map { entity in
            TwitterContent.URLEntity(url: entity.url, expandedURL: entity.expandedURL, displayURL: entity.displayURL)
        }
        return results ?? []
    }
    
    public func bioMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        guard let bio = self.bio else { return nil }
        let content = TwitterContent(content: bio, urlEntities: bioURLEntities)
        let metaContent = TwitterMetaContent.convert(
            document: content,
            urlMaximumLength: .max,
            twitterTextProvider: provider
        )
        return metaContent
    }
    
    public var urlEntity: [TwitterContent.URLEntity] {
        let results = urlEntities?.urls?.map { entity in
            TwitterContent.URLEntity(url: entity.url, expandedURL: entity.expandedURL, displayURL: entity.displayURL)
        }
        return results ?? []
    }
    
    public func urlMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        guard let url = self.url else { return nil }
        let content = TwitterContent(content: url, urlEntities: urlEntity)
        let metaContent = TwitterMetaContent.convert(
            document: content,
            urlMaximumLength: .max,
            twitterTextProvider: provider
        )
        return metaContent
    }
    
    public func locationMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        return location.flatMap { location -> TwitterMetaContent? in
            let location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !location.isEmpty else { return nil }
            let metaContent = TwitterMetaContent.convert(
                document: TwitterContent(content: location, urlEntities: []),
                urlMaximumLength: 50,
                twitterTextProvider: provider
            )
            return metaContent
        }
    }
}
