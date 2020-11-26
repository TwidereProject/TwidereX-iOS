//
//  Twitter+Entity+User+Entities.swift
//  
//
//  Created by Cirno MainasuK on 2020-11-26.
//

import Foundation

extension Twitter.Entity.User {
    public struct Entities: Codable {
        public let url: URL?
        public let description: Description?
    }
}

extension Twitter.Entity.User.Entities: Equatable { }

extension Twitter.Entity.User.Entities {
    
    public struct URL: Codable {
        public let urls: [URLNode]?
    }
    
    public struct Description: Codable {
        public let urls: [URLNode]?
    }
    
    public struct URLNode: Codable {
        public let url: String?
        public let expandedURL: String?
        public let displayURL: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case url = "url"
            case expandedURL = "expanded_url"
            case displayURL = "display_url"
            case indices = "indices"
        }
    }
    
}

extension Twitter.Entity.User.Entities.URL: Equatable { }
extension Twitter.Entity.User.Entities.Description: Equatable { }
extension Twitter.Entity.User.Entities.URLNode: Equatable { }
