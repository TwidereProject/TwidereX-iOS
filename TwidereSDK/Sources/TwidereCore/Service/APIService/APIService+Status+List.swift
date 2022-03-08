//
//  APIService+Status+List.swift
//  
//
//  Created by MainasuK on 2022-3-2.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

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

extension APIService {
    
    public func mastodonListStatuses(
        list: ManagedObjectRecord<MastodonList>,
        query: Mastodon.API.Timeline.TimelineQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            guard let list = list.object(in: managedObjectContext) else { return nil }
            return list.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.Timeline.list(
            session: session,
            domain: authenticationContext.domain,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist status
            for entity in response.value {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: me,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let _ = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
            }
        }
        
        return response
    }
    
}
