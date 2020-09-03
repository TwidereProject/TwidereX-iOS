//
//  URL.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-8-6.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation

public extension URL {
    
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        
        return fileContainer
            .appendingPathComponent("Databases", isDirectory: true)
            .appendingPathComponent("\(databaseName).sqlite")
    }
    
}
