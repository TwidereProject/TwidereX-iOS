//
//  Twitter+Entity+Trend+Place.swift
//  
//
//  Created by MainasuK on 2022-4-15.
//

import Foundation

extension Twitter.Entity.Trend {
    public struct Place: Codable {
        public let name: String
        public let woeid: Int
        public let parentID: Int
        
        public let placeType: PlaceType?
        public let country: String?
        public let countryCode: String?
        public let fullName: String?
        public let url: String?
        
        enum CodingKeys: String, CodingKey {
            case name
            case woeid
            case parentID = "parentid"
            
            case placeType = "place_type"
            case country
            case countryCode = "country_code"
            case fullName = "full_name"
            case url = "url"
        }
        
        public struct PlaceType: Codable {
            public let code: Int
            public let name: String
        }
    }
}

