//
//  Twitter+Entity+UserV2.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import Foundation

extension Twitter.Entity {
    public struct UserV2: Codable {
        
        public typealias ID = String
        
        // Fundamental
        public let id: ID
        public let name: String
        public let username: String
        
        // Extra
        
        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case username
        }
        
    }
}
