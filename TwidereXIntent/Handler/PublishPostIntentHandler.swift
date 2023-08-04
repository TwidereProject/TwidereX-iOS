//
//  PublishPostIntentHandler.swift
//  TwidereXIntent
//
//  Created by MainasuK on 2022-3-31.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import Intents
import CoreData
import CoreDataStack
import TwidereCore
import TwidereCommon

final class PublishPostIntentHandler: NSObject {
    
    let logger = Logger(subsystem: "SwitchAccountIntentHandler", category: "IntentHandler")

    let coreDataStack = CoreDataStack()
    lazy var managedObjectContext = coreDataStack.persistentContainer.viewContext
    
    lazy var api: APIService = {
        let backgroundManagedObjectContext = coreDataStack.newTaskContext()
        return APIService(
            coreDataStack: coreDataStack,
            backgroundManagedObjectContext: backgroundManagedObjectContext
        )
    }()
    
}

// MARK: - PublishPostIntentHandling
extension PublishPostIntentHandler: PublishPostIntentHandling {

    func handle(intent: PublishPostIntent) async -> PublishPostIntentResponse {
        guard let content = intent.content,
              let accounts = intent.accounts, !accounts.isEmpty
        else {
            return PublishPostIntentResponse(code: .failure, userActivity: nil)
        }
            
        do {
            let authenticationIndexes = try accounts.authenticationIndex(in: managedObjectContext)
            let authenticationContexts = authenticationIndexes.compactMap { authenticationIndex in
                AuthenticationContext(authenticationIndex: authenticationIndex, secret: AppSecret.default.secret)
            }
            
            var posts: [Post] = []
            for authenticationContext in authenticationContexts {
                let response = try await api.publishStatus(
                    context: APIService.PublishStatusContext(
                        content: content,
                        mastodonVisibility: {
                            switch intent.visibility {
                            case.unknown:       return nil
                            case .public:       return .public
                            case .unlisted:     return .unlisted
                            case .private:      return .private
                            case .direct:       return .direct
                            }
                        }(),
                        idempotencyKey: UUID().uuidString
                    ),
                    authenticationContext: authenticationContext
                )
                let post = Post(
                    identifier: response.id,
                    display: response.authorName,
                    subtitle: content,
                    image: response.authorAvatarURL.flatMap { INImage(url: $0) }
                )
                posts.append(post)
            }   // end for … in
            
            let intentResponse = PublishPostIntentResponse(code: .success, userActivity: nil)
            intentResponse.posts = posts
            
            return intentResponse
        } catch {
            let intentResponse = PublishPostIntentResponse(code: .failure, userActivity: nil)
            if let error = error as? LocalizedError {
                intentResponse.errorDescription = [
                    error.errorDescription,
                    error.failureReason,
                    error.recoverySuggestion
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
            } else {
                intentResponse.errorDescription = error.localizedDescription
            }
            return intentResponse
        }
    }   // end func

    func resolveContent(for intent: PublishPostIntent) async -> INStringResolutionResult {
        guard let content = intent.content?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            return INStringResolutionResult.needsValue()
        }
        
        return INStringResolutionResult.success(with: content)
    }

    func resolveAccounts(for intent: PublishPostIntent) async -> [AccountResolutionResult] {
        guard let accounts = intent.accounts, !accounts.isEmpty else {
            return [AccountResolutionResult.needsValue()]
        }
        
        let results = accounts.map { account in
            AccountResolutionResult.success(with: account)
        }
        
        return results
    }

    func provideAccountsOptionsCollection(for intent: PublishPostIntent) async throws -> INObjectCollection<Account> {
        let accounts = try await Account.fetch(in: managedObjectContext)
        return .init(items: accounts)
    }
    
    func resolveVisibility(for intent: PublishPostIntent) async -> TootVisibilityResolutionResult {
        return TootVisibilityResolutionResult.success(with: intent.visibility)
    }

}
