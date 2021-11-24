//
//  Mastodon+Entity+Emoji.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Emoji
    ///
    /// - Since: 2.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/emoji/)
    public struct Emoji: Codable {
        public typealias Shortcode = String
        
        public let shortcode: Shortcode
        public let url: String
        public let staticURL: String
        public let visibleInPicker: Bool
        
        public let category: String?
        
        enum CodingKeys: String, CodingKey {
            case shortcode
            case url
            case staticURL = "static_url"
            case visibleInPicker = "visible_in_picker"
            case category
        }
    }
}

extension Collection where Element == Mastodon.Entity.Emoji {
    public var asDictionary: [Mastodon.Entity.Emoji.Shortcode: String] {
        var dictionary: [Mastodon.Entity.Emoji.Shortcode: String] = [:]
        for emoji in self {
            dictionary[emoji.shortcode] = emoji.url
        }
        return dictionary
    }
}
