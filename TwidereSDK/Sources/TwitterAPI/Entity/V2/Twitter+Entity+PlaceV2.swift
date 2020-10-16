//
//  Twitter+Entity+PlaceV2.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-15.
//

import Foundation

extension Twitter.Entity {
    public struct PlaceV2: Codable {
        public let id: String
        public let fullName: String
        
        public let country: String?
        public let countryCode: String?
        public let name: String?
        public let placeType: String?
        // public let url: String?
        // public let geo
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case fullName = "full_name"
            
            case country = "country"
            case countryCode = "country_code"
            case name = "name"
            case placeType = "place_type"
            //case url = "url"
        }
    }
}
