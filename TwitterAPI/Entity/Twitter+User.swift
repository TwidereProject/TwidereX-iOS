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
        
        // trim-able
        
        public enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
        }
    }
}
