//
//  Twitter+Entity+V2+Tweet+Poll.swift
//  
//
//  Created by MainasuK on 2022-6-6.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct Poll: Codable, Identifiable {
        public typealias ID = String
        
        public let id: ID
        public let options: [Option]
        
        public let votingStatus: VotingStatus
        public let durationMinutes: Int?
        public let endDatetime: Date?
        
        public enum CodingKeys: String, CodingKey {
            case id
            case options
            case votingStatus = "voting_status"
            case durationMinutes = "duration_minutes"
            case endDatetime = "end_datetime"
        }
    }
}

extension Twitter.Entity.V2.Tweet.Poll {
    public enum VotingStatus: String, Codable, CaseIterable {
        case open
        case closed
    }
    
    public struct Option: Codable {
        public let position: Int
        public let label: String
        public let votes: Int
    }
}
