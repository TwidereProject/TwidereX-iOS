//
//  Twitter+User.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity {
    public struct User: Codable {
        
        public let idStr: String
        
        public let name: String?
        public let screenName: String?
        public let userDescription: String?
        
        public let location: String?
        public let url: String?
        //public let entities: FluffyEntities?
        public let protected: Bool?
        
        public let followersCount: Int?
        public let friendsCount: Int?
        public let listedCount: Int?
        public let favouritesCount: Int?
        public let statusesCount: Int?
        
        public let createdAt: Date?
        
        //public let utcOffset: JSONNull?
        //public let timeZone: JSONNull?
        public let geoEnabled: Bool?
        public let verified: Bool?
        //public let lang: JSONNull?
        public let contributorsEnabled: Bool?
        public let isTranslator: Bool?
        public let isTranslationEnabled: Bool?
        
        public let profileBackgroundColor: String?
        public let profileBackgroundImageURL: String?
        public let profileBackgroundImageURLHTTPS: String?
        public let profileBackgroundTile: Bool?
        public let profileImageURL: String?
        public let profileImageURLHTTPS: String?
        public let profileUseBackgroundImage: Bool?
        
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
        //public let translatorType: TranslatorType?
        
        enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
            
            case name = "name"
            case screenName = "screen_name"
            case userDescription = "description"
            
            case url = "url"
            case location = "location"
            //case entities = "entities"
            case protected = "protected"
            
            case followersCount = "followers_count"
            case friendsCount = "friends_count"
            case listedCount = "listed_count"
            case createdAt = "created_at"
            case favouritesCount = "favourites_count"
            
            //case utcOffset = "utc_offset"
            //case timeZone = "time_zone"
            case geoEnabled = "geo_enabled"
            case verified = "verified"
            case statusesCount = "statuses_count"
            //case lang = "lang"
            case contributorsEnabled = "contributors_enabled"
            case isTranslator = "is_translator"
            case isTranslationEnabled = "is_translation_enabled"
            
            case profileBackgroundColor = "profile_background_color"
            case profileBackgroundImageURL = "profile_background_image_url"
            case profileBackgroundImageURLHTTPS = "profile_background_image_url_https"
            case profileBackgroundTile = "profile_background_tile"
            case profileImageURL = "profile_image_url"
            case profileImageURLHTTPS = "profile_image_url_https"
            
            case profileBannerURL = "profile_banner_url"
            case profileLinkColor = "profile_link_color"
            case profileSidebarBorderColor = "profile_sidebar_border_color"
            case profileSidebarFillColor = "profile_sidebar_fill_color"
            case profileTextColor = "profile_text_color"
            case profileUseBackgroundImage = "profile_use_background_image"
            case hasExtendedProfile = "has_extended_profile"
            case defaultProfile = "default_profile"
            case defaultProfileImage = "default_profile_image"
            case following = "following"
            case followRequestSent = "follow_request_sent"
            case notifications = "notifications"
            //case translatorType = "translator_type"
        }
       
    }
}
