//
//  APIService+Status+List.swift
//  
//
//  Created by MainasuK on 2022-3-2.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension APIService {
    
    public func twitterListStatuses(
        list: ManagedObjectRecord<TwitterList>,
        query: Twitter.API.V2.Status.List.StatusesQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.List.StatusesContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            guard let list = list.object(in: managedObjectContext) else { return nil }
            return list.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.Status.List.statuses(
            session: session,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        if let statusIDs = response.value.data?.compactMap({ $0.id }), !statusIDs.isEmpty {
            _ = try await twitterStatus(
                statusIDs: statusIDs,
                authenticationContext: authenticationContext
            )
        }
        
        return response
    }
    
}
