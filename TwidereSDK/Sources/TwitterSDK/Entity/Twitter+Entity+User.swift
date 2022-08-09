//
//  Twitter+Entity+User.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity {
    public struct User: Codable {
        
        public typealias ID = String
        
        // Fundamental
        public let idStr: ID
        // nickname
        public let name: String
        /// @username without "@"
        public let screenName: String
        
        public let userDescription: String?
        public let entities: Entities?
        
        public let location: String?
        public let url: String?
        public let protected: Bool?
        
        public let followersCount: Int?
        public let friendsCount: Int?
        public let listedCount: Int?
        public let favouritesCount: Int?
        public let statusesCount: Int?
        
        public let createdAt: Date?
        
        public let geoEnabled: Bool?
        public let verified: Bool?
        public let contributorsEnabled: Bool?
        
        public let profileImageURLHTTPS: String?
        public let profileBannerURL: String?
        
        public let profileLinkColor: String?
        public let profileSidebarBorderColor: String?
        public let profileSidebarFillColor: String?
        public let profileTextColor: String?
        public let hasExtendedProfile: Bool?
        public let defaultProfile: Bool?
        public let defaultProfileImage: Bool?
        public let following: Bool?
        public let followRequestSent: Bool?
        public let notifications: Bool?
        
        enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
            
            case name = "name"
            case screenName = "screen_name"
            
            case userDescription = "description"
            case entities = "entities"
            
            case url = "url"
            case location = "location"
            case protected = "protected"
            
            case followersCount = "followers_count"
            case friendsCount = "friends_count"
            case listedCount = "listed_count"
            case createdAt = "created_at"
            case favouritesCount = "favourites_count"
            
            case geoEnabled = "geo_enabled"
            case verified = "verified"
            case statusesCount = "statuses_count"
            case contributorsEnabled = "contributors_enabled"
            
            case profileImageURLHTTPS = "profile_image_url_https"
            case profileBannerURL = "profile_banner_url"
            
            case profileLinkColor = "profile_link_color"
            case profileSidebarBorderColor = "profile_sidebar_border_color"
            case profileSidebarFillColor = "profile_sidebar_fill_color"
            case profileTextColor = "profile_text_color"
            case hasExtendedProfile = "has_extended_profile"
            case defaultProfile = "default_profile"
            case defaultProfileImage = "default_profile_image"
            case following = "following"
            case followRequestSent = "follow_request_sent"
            case notifications = "notifications"
        }
       
    }
}

extension Twitter.Entity.User: Equatable { }


extension Twitter.Entity.User {
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
        for suffixedSize in Twitter.Entity.User.ProfileImageSize.suffixedSizes {
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
