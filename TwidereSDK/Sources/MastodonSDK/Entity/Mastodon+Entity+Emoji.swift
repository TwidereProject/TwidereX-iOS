//
//  Mastodon+Entity+Emoji.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation
import OrderedCollections

extension Mastodon.Entity {
    /// Emoji
    ///
    /// - Since: 2.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/emoji/)
    public struct Emoji: Codable, Hashable {
        public typealias Shortcode = String
        public typealias Category = String
        
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

extension Mastodon.Entity.Emoji {
    
    public struct CategoryCollection {
        public let unindexed: [Mastodon.Entity.Emoji]
        public let orderedDictionary: OrderedDictionary<Mastodon.Entity.Emoji.Category, [Mastodon.Entity.Emoji]>
        
        public init(
            unindexed: [Mastodon.Entity.Emoji],
            orderedDictionary: OrderedDictionary<Mastodon.Entity.Emoji.Category, [Mastodon.Entity.Emoji]>
        ) {
            self.unindexed = unindexed
            self.orderedDictionary = orderedDictionary
        }
    }
}

extension Collection where Element == Mastodon.Entity.Emoji {
    public var asCategoryCollection: Mastodon.Entity.Emoji.CategoryCollection {
        var unindexed: [Mastodon.Entity.Emoji] = []
        var dictionary: OrderedDictionary<Mastodon.Entity.Emoji.Category, [Mastodon.Entity.Emoji]> = [:]
        
        for emoji in self {
            guard let category = emoji.category else {
                unindexed.append(emoji)
                continue
            }
            var array = dictionary[category] ?? []
            array.append(emoji)
            dictionary[category] = array
        }
        
        return .init(
            unindexed: unindexed,
            orderedDictionary: dictionary
        )
    }
}
