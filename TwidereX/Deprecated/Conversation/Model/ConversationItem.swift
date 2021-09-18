//
//  ConversationItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation
import CoreData
import TwitterSDK
import CoreDataStack

enum ConversationItem {
    case root(tweetObjectID: NSManagedObjectID)
    case reply(tweetObjectID: NSManagedObjectID)
    case leaf(tweetObjectID: NSManagedObjectID, attribute: LeafAttribute)
    case topLoader
    case bottomLoader
}

extension ConversationItem: Equatable {
    static func == (lhs: ConversationItem, rhs: ConversationItem) -> Bool {
        switch (lhs, rhs) {
        case (.root(let objectIDLeft), .root(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.reply(let objectIDLeft), .reply(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.leaf(let objectIDLeft, _), .leaf(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.topLoader, .topLoader):
            return true
        case (.bottomLoader, .bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension ConversationItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .root(let objectID):
            hasher.combine(objectID)
        case .reply(let objectID):
            hasher.combine(objectID)
        case .leaf(let objectID, _):
            hasher.combine(objectID)
        case .topLoader:
            hasher.combine(String(describing: ConversationItem.topLoader.self))
        case .bottomLoader:
            hasher.combine(String(describing: ConversationItem.bottomLoader.self))
        }
    }
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
