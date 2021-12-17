//
//  APIService+User+Report.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {

    public func reportForSpam(
        user: UserRecord,
        performBlock: Bool,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await reportForSpam(
                record: record,
                performBlock: performBlock,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await reportForSpam(
                record: record,
                authenticationContext: authenticationContext
            )
        default:
            assertionFailure()
            break
        }
    }

}

extension APIService {
    
    func reportForSpam(
        record: ManagedObjectRecord<TwitterUser>,
        performBlock: Bool,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let managedObjectContext = self.backgroundManagedObjectContext
        let authorization = authenticationContext.authorization
        
        let _query: Twitter.API.Users.ReportSpamQuery? = await managedObjectContext.perform {
            guard let user = record.object(in: managedObjectContext) else { return nil }
            return Twitter.API.Users.ReportSpamQuery(
                userID: user.id,
                performBlock: performBlock
            )
        }
        guard let query = _query else {
            assertionFailure()
            throw AppError.implicit(.badRequest)
        }
        
        let result: Result<Twitter.Response.Content<Twitter.Entity.User>, Error>
        do {
            let response = try await Twitter.API.Users.reportSpam(
                session: session,
                query: query,
                authorization: authorization
            )
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        if performBlock {
            // set blocking and remove following friendship
            try await managedObjectContext.performChanges {
                guard let user = record.object(in: managedObjectContext) else { return }
                guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else { return }
                
                user.update(isBlock: true, by: me)
                user.update(isFollow: false, by: me)
                user.update(isFollowRequestSent: false, from: me)
            }
        }
        
        let response = try result.get()
        return response
    }
    
    func reportForSpam(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Bool> {
        let managedObjectContext = self.backgroundManagedObjectContext
        
        let _query: Mastodon.API.Report.FileReportQuery? = await managedObjectContext.perform {
            guard let user = record.object(in: managedObjectContext) else { return nil }
            return Mastodon.API.Report.FileReportQuery(
                accountID: user.id,
                statusIDs: nil, // TODO:
                comment: nil,   // TODO:
                forward: nil
            )
        }
        guard let query = _query else {
            assertionFailure()
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.Report.fileReport(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        return response
    }
    
}
