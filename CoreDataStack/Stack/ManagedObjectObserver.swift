//
//  ManagedObjectObserver.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-6-12.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation
import CoreData
import Combine

final public class ManagedObjectObserver {
    private init() { }
}

extension ManagedObjectObserver {
    
    public static func observe(object: NSManagedObject) -> AnyPublisher<ChangeType?, Error> {
        guard let context = object.managedObjectContext else {
            return Fail(error: .noManagedObjectContext).eraseToAnyPublisher()
        }
        
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .tryMap { notification in
                guard let notification = ManagedObjectContextObjectsDidChangeNotification(notification: notification) else {
                    throw Error.notManagedObjectChangeNotification
                }
                
                let changeType = ManagedObjectObserver.changeType(of: object, in: notification)
                return changeType
            }
            .mapError { error -> Error in
                return (error as? Error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
}

extension ManagedObjectObserver {
    private static func changeType(of object: NSManagedObject, in notification: ManagedObjectContextObjectsDidChangeNotification) -> ChangeType? {
        let deleted = notification.deletedObjects.union(notification.invalidedObjects)
        if notification.invalidatedAllObjects || deleted.contains(where: { $0 === object}) {
            return .delete
        }
        
        let updated = notification.updatedObjects.union(notification.refreshedObjects)
        if updated.contains(where: { $0 === object}) {
            return .update
        }
        
        return nil
    }
}

extension ManagedObjectObserver {
    public enum ChangeType {
        case delete
        case update
    }
    
    public enum Error: Swift.Error {
        case unknown(Swift.Error)
        case noManagedObjectContext
        case notManagedObjectChangeNotification
    }
}
