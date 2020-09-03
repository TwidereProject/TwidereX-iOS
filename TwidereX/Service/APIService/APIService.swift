//
//  APIService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation
import Combine
import CoreData
import TwitterAPI

final class APIService {
        
    let session: URLSession
    
    // input
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext, backgroundManagedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.session = URLSession(configuration: .default)
        
        // setup cache
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
    }
    
}
