//
//  Twitter+Entity+V2+Tweet+Geo.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct Geo: Codable {
        public let coordinates: [Coordinate]?
    }
}

extension Twitter.Entity.V2.Tweet.Geo {
    public struct Coordinate: Codable {
        public let type: String
        public let coordinates: [Double]
    }
}
