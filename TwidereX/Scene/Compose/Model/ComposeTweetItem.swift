//
//  ComposeTweetItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

enum ComposeTweetItem {
    case reply(objectID: NSManagedObjectID)
    case input(attribute: InputAttribute)
    case quote(objectID: NSManagedObjectID)
}

extension ComposeTweetItem: Hashable { }

extension ComposeTweetItem {
    class InputAttribute: Hashable {
        let hasReplyTo: Bool
        
        init(hasReplyTo: Bool) {
            self.hasReplyTo = hasReplyTo
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(hasReplyTo)
        }
        
        static func == (lhs: ComposeTweetItem.InputAttribute, rhs: ComposeTweetItem.InputAttribute) -> Bool {
            return lhs.hasReplyTo == rhs.hasReplyTo
        }
    }
}
