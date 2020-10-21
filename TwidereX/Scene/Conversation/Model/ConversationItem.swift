//
//  ConversationItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation
import CoreData
import TwitterAPI
import CoreDataStack

enum ConversationItem: Hashable {
    case root(tweetObjectID: NSManagedObjectID)
    case leaf(tweetObjectID: NSManagedObjectID, attribute: LeafAttribute)
    case bottomLoader
}

extension ConversationItem {
    class LeafAttribute: Hashable {
        let identifier = UUID()
        let tweetID: Tweet.ID
        var level: Int = 0
        var hasReply: Bool = true
                
        init(tweetID: Tweet.ID, level: Int, hasReply: Bool = true) {
            self.tweetID = tweetID
            self.level = level
            self.hasReply = hasReply
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func == (lhs: ConversationItem.LeafAttribute, rhs: ConversationItem.LeafAttribute) -> Bool {
            return lhs.identifier == rhs.identifier &&
                lhs.hasReply == rhs.hasReply
        }
    }
}
