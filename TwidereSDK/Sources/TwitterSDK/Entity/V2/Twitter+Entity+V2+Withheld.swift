//
//  Twitter+Entity+V2+Tweet+Withheld.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct Withheld: Codable, Hashable {
        public let copyright: Bool?
        public let countryCodes: [String]?
        
        public enum CodingKeys: String, CodingKey {
            case copyright
            case countryCodes = "country_codes"
        }
    }
}
