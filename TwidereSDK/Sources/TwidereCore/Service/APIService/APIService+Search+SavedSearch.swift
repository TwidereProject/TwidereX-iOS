//
//  APIService+Search+SavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation
import TwitterSDK
import CoreDataStack

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
    
    public func createTwitterSavedSearch(
        text: String,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.SavedSearch> {
        let query = Twitter.API.SavedSearch.CreateQuery(query: text)
        let response = try await Twitter.API.SavedSearch.create(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        
        try await managedObjectContext.performChanges {
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                throw AppError.implicit(.authenticationMissing)
            }
            _ = Persistence.TwitterSavedSearch.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterSavedSearch.PersistContext(
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
    
    public func destoryTwitterSavedSearch(
        savedSearch: ManagedObjectRecord<TwitterSavedSearch>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.SavedSearch> {
        let managedObjectContext = backgroundManagedObjectContext

        let _id: TwitterSavedSearch.ID? = await managedObjectContext.perform {
            let object = savedSearch.object(in: managedObjectContext)
            return object?.id
        }
        
        guard let id = _id else {
            throw AppError.implicit(.badRequest)
        }

        
        let response = try await Twitter.API.SavedSearch.destroy(
            session: session,
            id: id,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            guard let object = savedSearch.object(in: managedObjectContext) else { return }
            managedObjectContext.delete(object)
        }
        
        return response
    }
    
}
