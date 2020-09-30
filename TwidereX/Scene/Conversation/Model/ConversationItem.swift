//
//  ConversationItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation
import CoreData
import TwitterAPI

enum ConversationItem: Hashable {
    case root(RootItem)
}

extension ConversationItem {
    enum RootItem {
        case objectID(objectID: NSManagedObjectID)
        case entity(tweet: Twitter.Entity.Tweet)
    }
}

extension ConversationItem.RootItem: Hashable { }
