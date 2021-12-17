//
//  APIService+Search.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK
import CoreDataStack

// MARK: - Mastodon

extension APIService {
    
    public func searchMastodon(
        query: Mastodon.API.V2.Search.SearchQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.SearchResult> {
        let response = try await Mastodon.API.V2.Search.search(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let _relationshipResponse: Mastodon.Response.Content<[Mastodon.Entity.Relationship]>? = await {
            let userIDs = response.value.accounts.map { $0.id }
            guard !userIDs.isEmpty else { return nil }

            let relationshipQuery = Mastodon.API.Account.RelationshipQuery(ids: userIDs)
            do {
                let relationshipResponse = try await Mastodon.API.Account.relationships(
                    session: session,
                    domain: authenticationContext.domain,
                    query: relationshipQuery,
                    authorization: authenticationContext.authorization
                )
                return relationshipResponse
            } catch {
                return nil
            }
        }()
        let _relationshipDictionary = _relationshipResponse?.value.toDictionary()
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let _me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist statuses
            for status in response.value.statuses {
                let result = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonStatus.PersistContext(
                        domain: authenticationContext.domain,
                        entity: status,
                        me: _me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                #if DEBUG
                result.log()
                #endif
            }
            
            // persist users
            for account in response.value.accounts {
                let result = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: authenticationContext.domain,
                        entity: account,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                let user = result.user
                guard let me = _me,
                      let relationshipResponse = _relationshipResponse,
                      let relationship = _relationshipDictionary?[account.id]
                else { continue }
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: relationshipResponse.networkDate
                    )
                )
            }
        }   // try await managedObjectContext.performChanges
        return response
    }
}
