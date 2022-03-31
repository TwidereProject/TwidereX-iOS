//
//  AuthenticationIndex+Fetch.swift
//  TwidereXIntent
//
//  Created by MainasuK on 2022-3-31.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import Intents

extension AuthenticationIndex {

    static func fetch(in managedObjectContext: NSManagedObjectContext) throws -> [AuthenticationIndex] {
        let request = AuthenticationIndex.sortedFetchRequest
        let results = try managedObjectContext.fetch(request)
        return results
    }
    
}
