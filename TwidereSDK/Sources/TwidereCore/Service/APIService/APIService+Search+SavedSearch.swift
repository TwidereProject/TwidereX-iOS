//
//  APIService+Search+SavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation
import TwitterSDK

extension APIService {
    
    public func twitterSavedSearches(
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.SavedSearch]> {
        let response = try await Twitter.API.SavedSearch.list(
            session: session,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        
        try await managedObjectContext.performChanges {
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                throw AppError.implicit(.authenticationMissing)
            }
            for entity in response.value {
                _ = Persistence.TwitterSavedSearch.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterSavedSearch.PersistContext(
                        entity: entity,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }
    
}
