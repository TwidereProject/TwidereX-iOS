//
//  RemoteProfileViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwidereCore
import TwitterSDK

final class RemoteProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, profileContext: ProfileContext) {
        super.init(context: context)
        
        configure(profileContext: profileContext)
    }
    
    func configure(profileContext: ProfileContext) {
        switch profileContext {
        case .record(let record):
            setup(user: record)
        case .twitter(let twitterContext):
            Task {
                guard case let .twitter(authenticationContext) = context.authenticationService.activeAuthenticationContext.value else { return }
                do {
                    let _record = try await fetchTwitterUser(
                        twitterContext: twitterContext,
                        authenticationContext: authenticationContext
                    )
                    guard let record = _record else { return }
                    await self.setup(user: .twitter(record: record))
                } catch {
                    // do nothing
                }
            }
//        case .mastodon(let mastodonContext):
//            break
        }
    }
    
}

extension RemoteProfileViewModel {
 
    enum ProfileContext {
        // case twitter(userID: TwitterUser.ID)
        case record(record: UserRecord)
        case twitter(TwitterContext)
        // case mastodon(MastodonContext)
        
        enum TwitterContext {
            case userID(TwitterUser.ID)
            case username(String)
        }
        
        enum MastodonContext {
            case username(String)
        }
    }
    
    // note:
    // use sync method to force data prepared before using
    // otherwise, the UI may delay update when profile display
    func setup(user record: UserRecord) {
        let managedObjectContext = context.managedObjectContext
        managedObjectContext.performAndWait {
            switch record {
            case .twitter(let record):
                guard let object = record.object(in: managedObjectContext) else { return }
                self.user = .twitter(object: object)
            case .mastodon(let record):
                guard let object = record.object(in: managedObjectContext) else { return }
                self.user = .mastodon(object: object)
            }
        }
    }   // end func setup(user:)
    
    // async method on main queue for concurrency way call
    @MainActor
    func setup(user record: UserRecord) async {
        self.user = record.object(in: context.managedObjectContext)
    }
    
}

extension RemoteProfileViewModel {
    func findTwitterUser(userID: TwitterUser.ID) -> ManagedObjectRecord<TwitterUser>? {
        let request = TwitterUser.sortedFetchRequest
        request.predicate = TwitterUser.predicate(id: userID)
        request.fetchLimit = 1
        guard let user = try? context.managedObjectContext.fetch(request).first else { return nil }
        return .init(objectID: user.objectID)
    }
}

extension RemoteProfileViewModel {
    
    func fetchTwitterUser(
        twitterContext: ProfileContext.TwitterContext,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> ManagedObjectRecord<TwitterUser>? {
        let response: Twitter.Response.Content<Twitter.API.V2.UserLookup.Content> = try await {
            switch twitterContext {
            case .userID(let userID):
                return try await context.apiService.twitterUsers(
                    userIDs: [userID],
                    twitterAuthenticationContext: authenticationContext
                )
            case .username(let username):
                return try await context.apiService.twitterUsers(
                    usernames: [username],
                    twitterAuthenticationContext: authenticationContext
                )
            }   // end switch
        }()
        guard let entity = response.value.data?.first else { return nil }
        let record = findTwitterUser(userID: entity.id)
        return record
    }
    
    func fetchMastodonUser(
        username: String,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> StatusRecord? {
        assertionFailure()
        return nil
    }
    
}
