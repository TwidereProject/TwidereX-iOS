//
//  APIService+Status+Delete.swift
//  
//
//  Created by MainasuK on 2021-12-16.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func deleteStatus(
        record: StatusRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (record, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await deleteTwitterStatus(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            assertionFailure()
        default:
            assertionFailure()
            return
        }
    }
    
    public func deleteTwitterStatus(
        record: ManagedObjectRecord<TwitterStatus>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.Delete.DeleteContent> {
        let authorization = authenticationContext.authorization
        let managedObjectContext = backgroundManagedObjectContext

        let _statusID: Twitter.Entity.V2.Tweet.ID? = await managedObjectContext.perform {
            guard let status = record.object(in: managedObjectContext) else { return nil }
            return status.id
        }
        
        guard let statusID = _statusID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.Status.Delete.delete(
            session: session,
            statusID: statusID,
            authorization: authorization
        )
        
        try await managedObjectContext.performChanges {
            guard response.value.data.deleted else { return }
            guard let status = record.object(in: managedObjectContext) else { return }

            for feed in status.feeds {
                managedObjectContext.delete(feed)
            }
            for repostFrom in status.repostFrom {
                managedObjectContext.delete(repostFrom)
            }
            managedObjectContext.delete(status)
        }
        
        return response
    }
    
}
