//
//  APIService+Status+List.swift
//  
//
//  Created by MainasuK on 2022-3-2.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

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
            assert(statusIDs.count <= 100)
            _ = try await twitterStatus(
                statusIDs: statusIDs,
                authenticationContext: authenticationContext
            )
        }
        
        return response
    }
    
    public func twitterListStatusesV1(
        query: Twitter.API.List.StatusesQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let response = try await Twitter.API.List.statuses(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )

        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            // log rate limit
            response.logRateLimit()
            
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            var statusArray: [TwitterStatus] = []
            for entity in response.value {
                let result = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: .init(
                        entity: entity,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                statusArray.append(result.status)
            }   // end for in
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
