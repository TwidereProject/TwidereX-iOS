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
    case root(objectID: NSManagedObjectID)
}
