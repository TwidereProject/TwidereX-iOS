//
//  Twitter+Entity+V2+Media.swift
//  
//
//  Created by Cirno MainasuK on 2020/10/21.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct Media: Codable, Identifiable {
        public typealias ID = String
        
        public var id: ID { mediaKey }

        public let mediaKey: ID
        public let type: String
        
        public let durationMS: Int?
        public let width: Int?
        public let height: Int?
        public let url: String?
        public let previewImageURL: String?
        public let publicMetrics: PublicMetrics?
        public let altText: String?
        
        enum CodingKeys: String, CodingKey {
            case mediaKey = "media_key"
            case type
            
            case durationMS = "duration_ms"
            case width
            case height
            case url
            case previewImageURL = "preview_image_url"
            case publicMetrics = "public_metrics"
            case altText = "alt_text"
        }
    }
}
