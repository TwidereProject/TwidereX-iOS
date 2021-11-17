//
//  Twitter+Response+V2+ContentError.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-22.
//

import Foundation

extension Twitter.Response.V2 {
    public struct ContentError: Codable {
        public let detail: String
        public let title: String
        public let resourceType: String
        public let parameter: String
        public let value: String
        public let type: String
        
        public enum CodingKeys: String, CodingKey {
            case detail
            case title
            case resourceType = "resource_type"
            case parameter
            case value
            case type
        }
    }
}
