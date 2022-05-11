//
//  MastodonMention.swift
//  
//
//  Created by MainasuK on 2022-4-11.
//

import Foundation

public final class MastodonMention: NSObject, Codable {
    public typealias ID = String
    
    public let id: ID
    public let username: String
    public let url: String
    public let acct: String
    
    public init(id: MastodonMention.ID, username: String, url: String, acct: String) {
        self.id = id
        self.username = username
        self.url = url
        self.acct = acct
    }
}
