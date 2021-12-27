//
//  Twitter+Entity+SavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation

extension Twitter.Entity {
    public struct SavedSearch: Codable {
        public typealias ID = String
        
        public let idStr: ID
        public let name: String
        public let query: String
        public let createdAt: Date
        
        enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
            case name
            case query
            case createdAt = "created_at"
        }
    }
}
