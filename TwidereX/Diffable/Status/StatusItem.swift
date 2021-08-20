//
//  StatusItem.swift
//  StatusItem
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

enum StatusItem: Hashable {
    case homeTimelineFeed(record: ManagedObjectRecord<Feed>)
    case twitterStatus(record: ManagedObjectRecord<TwitterStatus>)
}

class ManagedObjectRecord<T: Managed>: Hashable {
    
    let objectID: NSManagedObjectID
    
    init(objectID: NSManagedObjectID) {
        self.objectID = objectID
    }
    
    func object(in managedObjectContext: NSManagedObjectContext) -> T? {
        do {
            return try managedObjectContext.existingObject(with: objectID) as? T
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    
    static func == (lhs: ManagedObjectRecord<T>, rhs: ManagedObjectRecord<T>) -> Bool {
        return lhs.objectID == rhs.objectID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }

}
