//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020/10/21.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct Attachments: Codable {
        public let mediaKeys: [Twitter.Entity.V2.Media.ID]?
        public let pollIDs: [Twitter.Entity.V2.Tweet.Poll.ID]?
        
        public enum CodingKeys: String, CodingKey {
            case mediaKeys = "media_keys"
            case pollIDs = "poll_ids"
        }
    }
}
