//
//  NSManagedObjectContext.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os
import Foundation
import Combine
import CoreData

extension NSManagedObjectContext {
    public func insert<T: NSManagedObject>() -> T where T: Managed {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T else {
            fatalError("cannot insert object: \(T.self)")
        }
        
        return object
    }
    
    public func saveOrRollback() throws {
        do {
            guard hasChanges else {
                return
            }
            try save()
        } catch {
            rollback()
            
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            debugPrint(error)
            throw error
        }
    }
    
    public func performChanges(block: @escaping () -> Void) -> Future<Result<Void, Error>, Never> {
        Future { promise in
            self.perform {
                block()
                do {
                    try self.saveOrRollback()
                    promise(.success(Result.success(())))
                } catch {
                    promise(.success(Result.failure(error)))
                }
            }
        }
    }
    
    public func performChanges<T>(block: @escaping () throws -> T) async throws -> T {
        try await perform(schedule: .enqueued) {
            let value = try block()
            try self.saveOrRollback()
            return value
        }
    }

}


extension NSManagedObjectContext {
    static let objectCacheKey = "ObjectCacheKey"
    private typealias ObjectCache = [String: NSManagedObject]
    
    public func cache(
        _ object: NSManagedObject?,
        key: String
    ) {
        var cache = userInfo[NSManagedObjectContext.objectCacheKey] as? ObjectCache ?? [:]
        cache[key] = object
        userInfo[NSManagedObjectContext.objectCacheKey] = cache
    }
    
    public func cache(froKey key: String) -> NSManagedObject? {
        guard let cache = userInfo[NSManagedObjectContext.objectCacheKey] as? ObjectCache
        else { return nil }
        return cache[key]
    }
}
