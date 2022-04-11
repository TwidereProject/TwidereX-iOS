//
//  Account.swift
//  TwidereXIntent
//
//  Created by MainasuK on 2022-3-31.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import Intents

extension Account {

    @MainActor
    static func fetch(in managedObjectContext: NSManagedObjectContext) async throws -> [Account] {
        // get accounts
        let accounts: [Account] = try await managedObjectContext.perform {
            let results = try AuthenticationIndex.fetch(in: managedObjectContext)
            let accounts = results.compactMap { authenticationIndex -> Account? in
                guard let object = authenticationIndex.account else { return nil }
                let account = Account(
                    identifier: authenticationIndex.identifier.uuidString,
                    display: object.name,
                    subtitle: object.username,
                    image: object.avatarURL.flatMap { INImage(url: $0) }
                )
                account.name = object.name
                account.username = object.username
                return account
            }
            return accounts
        }   // end managedObjectContext.perform

        return accounts
    }
    
}

extension Array where Element == Account {
    func authenticationIndex(in managedObjectContext: NSManagedObjectContext) throws -> [AuthenticationIndex] {
        let identifiers = self
            .compactMap { $0.identifier }
            .compactMap { UUID(uuidString: $0) }
        let request = AuthenticationIndex.sortedFetchRequest
        request.predicate = AuthenticationIndex.predicate(identifiers: identifiers)
        let results = try managedObjectContext.fetch(request)
        return results
    }
    
}
