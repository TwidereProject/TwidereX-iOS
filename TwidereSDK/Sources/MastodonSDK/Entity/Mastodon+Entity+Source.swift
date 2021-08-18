//
//  Mastodon+Entity+Source.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Source
    ///
    /// - Since: 1.5.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/3
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/source/)
    public struct Source: Codable {
        
        // Base
        public let note: String
        public let fields: [Field]?
        
        public let privacy: Privacy?
        public let sensitive: Bool?
        public let language: String?        // (ISO 639-1 language two-letter code)
        public let followRequestsCount: Int?
        
        enum CodingKeys: String, CodingKey {
            case note
            case fields
            
            case privacy
            case sensitive
            case language
            case followRequestsCount = "follow_requests_count"
        }
    }
}

extension Mastodon.Entity.Source {
    public enum Privacy: RawRepresentable, Codable {
        case `public`
        case unlisted
        case `private`
        case direct
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "public":                  self = .public
            case "unlisted":                self = .unlisted
            case "private":                 self = .private
            case "direct":                  self = .direct
            default:                        self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .public:                       return "public"
            case .unlisted:                     return "unlisted"
            case .private:                      return "private"
            case .direct:                       return "direct"
            case ._other(let value):            return value
            }
        }
    }
}
