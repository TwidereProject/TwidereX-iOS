//
//  Twitter+Entity+Coordinates.swift
//  TwitterSDK
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation

extension Twitter.Entity {
    public struct Coordinates: Codable {
        public var type: String
        public var coordinates: [Double]
    }
}

extension Twitter.Entity.Coordinates: Equatable { }
