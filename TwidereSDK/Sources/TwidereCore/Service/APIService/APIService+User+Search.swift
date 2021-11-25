//
//  APIService+User+Search.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwitterSDK
    
extension APIService {
    // v1 API
    public func searchTwitterUser(
        query: Twitter.API.Users.SearchQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.User]> {
        let response = try await Twitter.API.Users.search(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            let me = authentication?.user
            for entity in response.value {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContext(
                        entity: entity,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in …
        }   // end managedObjectContext.performChanges
        return response
    }   // end func searchTwitterUser
}
