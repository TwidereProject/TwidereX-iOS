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
    case input
    case quote(objectID: NSManagedObjectID)
}

extension ComposeTweetItem: Hashable { }
