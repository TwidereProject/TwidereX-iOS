//
//  Twitter+Entity+V2+Place.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-15.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct Place: Codable, Identifiable {
        public typealias ID = String
        
        public let id: ID
        public let fullName: String
        
        public let country: String?
        public let countryCode: String?
        public let name: String?
        public let placeType: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case fullName = "full_name"
            
            case country = "country"
            case countryCode = "country_code"
            case name = "name"
            case placeType = "place_type"
        }
    }
}
