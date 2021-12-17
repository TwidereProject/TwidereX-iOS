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
    public func bioMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        let _bioContent: String? = bio.flatMap { text in
            var text = text
            for url in bioEntities?.urls ?? [] {
                guard let expandedURL = url.expandedURL else { continue }
                let shortURL = url.url
                text = text.replacingOccurrences(of: shortURL, with: expandedURL)
            }
            return text
        }
        guard let bioContent = _bioContent else { return nil }
        let content = TwitterContent(content: bioContent)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 50,
            twitterTextProvider: provider
        )
        return metaContent
    }
    
    public func urlMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        let _urlContent: String? = url.flatMap { text in
            var text = text
            for url in urlEntities?.urls ?? [] {
                guard let expandedURL = url.expandedURL else { continue }
                let shortURL = url.url
                text = text.replacingOccurrences(of: shortURL, with: expandedURL)
            }
            return text
        }
        guard let urlContent = _urlContent else { return nil }
        let content = TwitterContent(content: urlContent)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 50,
            twitterTextProvider: provider
        )
        return metaContent
    }
    
    public func locationMetaContent(provider: TwitterTextProvider) -> TwitterMetaContent? {
        return location.flatMap { location in
            let location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !location.isEmpty else { return nil }
            let metaContent = TwitterMetaContent.convert(
                content: TwitterContent(content: location),
                urlMaximumLength: 50,
                twitterTextProvider: provider
            )
            return metaContent
        }
    }
}
