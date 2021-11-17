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
    
    public var insertedObjects: Set<NSManagedObject> {
        return objects(forKey: NSInsertedObjectsKey)
    }
    
    public var updatedObjects: Set<NSManagedObject> {
        return objects(forKey: NSUpdatedObjectsKey)
    }
    
    public var deletedObjects: Set<NSManagedObject> {
        return objects(forKey: NSDeletedObjectsKey)
    }
    
    public var refreshedObjects: Set<NSManagedObject> {
        return objects(forKey: NSRefreshedObjectsKey)
    }
    
    public var invalidedObjects: Set<NSManagedObject> {
        return objects(forKey: NSInvalidatedObjectsKey)
    }
    
    public var invalidatedAllObjects: Bool {
        return notification.userInfo?[NSInvalidatedAllObjectsKey] != nil
    }
    
}

extension ManagedObjectContextObjectsDidChangeNotification {
    
    private func objects(forKey key: String) -> Set<NSManagedObject> {
        return notification.userInfo?[key] as? Set<NSManagedObject> ?? Set()
    }
    
}
