//
//  Twitter+Place.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity {
    public struct Place: Codable {
        public let id: String

        public let country: String?
        public let countryCode: String?
        public let fullName: String?
        public let name: String?
        public let placeType: String?
        public let url: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "id"

            case country = "country"
            case countryCode = "country_code"
            case fullName = "full_name"
            case name = "name"
            case placeType = "place_type"
            case url = "url"
        }
    }    
}
