//
//  ManagedObjectContextObjectsDidChange.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-6-12.
//

import Foundation
import CoreData

public struct ManagedObjectContextObjectsDidChangeNotification {
    
    public let notification: Notification
    public let managedObjectContext: NSManagedObjectContext
    
    public init?(notification: Notification) {
        guard notification.name == .NSManagedObjectContextObjectsDidChange,
            let managedObjectContext = notification.object as? NSManagedObjectContext else {
            return nil
        }
        
        self.notification = notification
        self.managedObjectContext = managedObjectContext
    }
    
}

extension ManagedObjectContextObjectsDidChangeNotification {
    
    var insertedObjects: Set<NSManagedObject> {
        return objects(forKey: NSInsertedObjectsKey)
    }
    
    var updatedObjects: Set<NSManagedObject> {
        return objects(forKey: NSUpdatedObjectsKey)
    }
    
    var deletedObjects: Set<NSManagedObject> {
        return objects(forKey: NSDeletedObjectsKey)
    }
    
    var refreshedObjects: Set<NSManagedObject> {
        return objects(forKey: NSRefreshedObjectsKey)
    }
    
    var invalidedObjects: Set<NSManagedObject> {
        return objects(forKey: NSInvalidatedObjectsKey)
    }
    
    var invalidatedAllObjects: Bool {
        return notification.userInfo?[NSInvalidatedAllObjectsKey] != nil
    }
    
}

extension ManagedObjectContextObjectsDidChangeNotification {
    
    private func objects(forKey key: String) -> Set<NSManagedObject> {
        return notification.userInfo?[key] as? Set<NSManagedObject> ?? Set()
    }
    
}
