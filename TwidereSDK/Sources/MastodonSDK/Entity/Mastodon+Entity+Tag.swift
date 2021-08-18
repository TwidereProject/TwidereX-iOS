//
//  Mastodon+Entity+Tag.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Tag
    ///
    /// - Since: 0.9.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/tag/)
    public struct Tag: Codable {
        // Base
        public let name: String
        public let url: String
        
        public let history: [History]?
        enum CodingKeys: String, CodingKey {
            case name
            case url
            case history
        }
    }
}
