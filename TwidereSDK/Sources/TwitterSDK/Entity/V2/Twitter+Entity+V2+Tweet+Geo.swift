//
//  Twitter+Entity+V2+Tweet+Geo.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct Geo: Codable {
        public let placeID: Twitter.Entity.V2.Place.ID?
        public let coordinates: Coordinate?
        
        public init(
            placeID: Twitter.Entity.V2.Place.ID?,
            coordinates: Twitter.Entity.V2.Tweet.Geo.Coordinate? = nil
        ) {
            self.placeID = placeID
            self.coordinates = coordinates
        }
        
        public enum CodingKeys: String, CodingKey {
            case placeID = "place_id"
            case coordinates
        }
    }
}

extension Twitter.Entity.V2.Tweet.Geo {
    public struct Coordinate: Codable {
        public let type: String
        public let coordinates: [Double]
    }
}
