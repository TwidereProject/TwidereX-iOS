//
//  Twitter+Entity+DirectMessage+Event.swift
//  
//
//  Created by MainasuK on 2022-8-5.
//

import Foundation

extension Twitter.Entity.DirectMessage {
    public struct Event: Codable {
        public typealias ID = String
        
        public let id: ID
        public let type: String
        
    }
}
