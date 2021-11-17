//
//  Twitter+Entity+V2+Media+PublicMetrics.swift
//  
//
//  Created by Cirno MainasuK on 2020/10/21.
//

import Foundation

extension Twitter.Entity.V2.Media {
    public struct PublicMetrics: Codable {
        public let viewCount: Int?
        
        public enum CodingKeys: String, CodingKey {
            case viewCount = "view_count"
        }
    }
}
