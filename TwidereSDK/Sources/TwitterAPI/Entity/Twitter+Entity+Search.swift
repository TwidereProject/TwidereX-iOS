//
//  Twitter+Entity+Search.swift
//  
//
//  Created by Cirno MainasuK on 2021-1-20.
//

import Foundation

extension Twitter.Entity {
    public class Search: Codable {
        
        public let statuses: [Tweet]?
        public let searchMetadata: SearchMetadata
        
        public enum CodingKeys: String, CodingKey {
            case statuses
            case searchMetadata = "search_metadata"
        }
        
        public struct SearchMetadata: Codable {
            public let nextResults: String
            public let query: String
            public let count: Int
            
            public enum CodingKeys: String, CodingKey {
                case nextResults = "next_results"
                case query
                case count
            }
        }
        
    }
}
