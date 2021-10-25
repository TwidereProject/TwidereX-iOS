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
    
    func searchMastodon(
        query: Mastodon.API.V2.Search.SearchQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.SearchResult> {
        let response = try await Mastodon.API.V2.Search.search(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist statuses
            for status in response.value.statuses {
                _ = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonStatus.PersistContext(
                        domain: authenticationContext.domain,
                        entity: status,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
            // persist users
            for account in response.value.accounts {
                _ = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: authenticationContext.domain,
                        entity: account,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
        }   // try await managedObjectContext.performChanges
        return response
    }
}
