//
//  Twitter+Entity+List.swift
//  
//
//  Created by MainasuK on 2022-3-10.
//

import Foundation

// Note:
// use the v2 as the persist model
// this model is for query following relationship only
extension Twitter.Entity {
    public struct List: Codable {
        public typealias ID = String
        
        public let id: ID

        public let name: String
        public let uri: String
        public let following: Bool
        
        
        enum CodingKeys: String, CodingKey {
            case id = "id_str"

            case name
            case uri
            case following
        }
    }
}
