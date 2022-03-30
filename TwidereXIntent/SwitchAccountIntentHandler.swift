//
//  SwitchAccountIntentHandler.swift
//  TwidereXIntent
//
//  Created by MainasuK on 2022-3-30.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import Intents
import CoreData
import CoreDataStack
import TwidereCore
import TwidereCommon

final class SwitchAccountIntentHandler: NSObject {
    
    let logger = Logger(subsystem: "SwitchAccountIntentHandler", category: "IntentHandler")

    let coreDataStack = CoreDataStack()
    lazy var managedObjectContext = coreDataStack.persistentContainer.viewContext
    
}

// MARK: - SwitchAccountIntentHandling
extension SwitchAccountIntentHandler: SwitchAccountIntentHandling {
    
    func handle(intent: SwitchAccountIntent) async -> SwitchAccountIntentResponse {
        let activity = NSUserActivity(activityType: "com.twidere.twiderex.switch-account")
        let response = SwitchAccountIntentResponse(code: .continueInApp, userActivity: activity)
        return response
    }
    
    
    func resolveAccount(for intent: SwitchAccountIntent) async -> AccountResolutionResult {
        guard let account = intent.account else {
            return AccountResolutionResult.needsValue()
        }
        return AccountResolutionResult.success(with: account)
    }
    
    
    func provideAccountOptionsCollection(for intent: SwitchAccountIntent) async throws -> INObjectCollection<Account> {
        let accounts = try await fetchAccounts()
        return .init(items: accounts)
    }
    
}


extension SwitchAccountIntentHandler {
        
    @MainActor
    func fetchAccounts() async throws -> [Account] {
        let managedObjectContext = managedObjectContext
        
        // get accounts
        let accounts: [Account] = try await managedObjectContext.perform {
            let request = AuthenticationIndex.sortedFetchRequest
            let results = try managedObjectContext.fetch(request)
            
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
