//
//  APIService+Repost.swift
//  APIService+Repost
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import TwitterSDK
import Alamofire
import UIKit

extension APIService {
    
    func repost(
        status: DataSourceItem.Status,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (status, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await repost(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            assertionFailure()
        default:
            assertionFailure()
        }
    }
    
    private struct RepostContext {
        let statusID: TwitterStatus.ID
        let isReposted: Bool
        let repostedCount: Int64
    }
    
    func repost(
        record: ManagedObjectRecord<TwitterStatus>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Retweet.RetweetContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update repost state and retrieve repost context
        let _repostContext: RepostContext? = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return nil }
            let user = authentication.twitterUser
            let status = _status.repost ?? _status
            let isReposted = status.repostBy.contains(user)
            let repostedCount = status.repostCount
            let repostCount = isReposted ? repostedCount - 1 : repostedCount + 1
            status.update(isRepost: !isReposted, user: user)
            status.update(repostCount: Int64(max(0, repostCount)))
            let repostContext = RepostContext(
                statusID: status.id,
                isReposted: isReposted,
                repostedCount: repostedCount
            )
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status repost: \(!isReposted), \(repostCount)")
            return repostContext
        }
        guard let repostContext = _repostContext else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        // request repost or undo repost
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Retweet.RetweetContent>, Error>
        do {
            if repostContext.isReposted {
                let response = try await Twitter.API.V2.User.Retweet.undoRetweet(
                    session: session,
                    userID: authenticationContext.userID,
                    statusID: repostContext.statusID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let query = Twitter.API.V2.User.Retweet.RetweetQuery(
                    tweetID: repostContext.statusID
                )
                let response = try await Twitter.API.V2.User.Retweet.retweet(
                    session: session,
                    query: query,
                    userID: authenticationContext.userID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update repost failure: \(error.localizedDescription)")
        }
        
        // update repost state
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return }
            let user = authentication.twitterUser
            let status = _status.repost ?? _status

            switch result {
            case .success(let response):
                let isRepost = response.value.data.retweeted
                status.update(isRepost: isRepost, user: user)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status repost: \(isRepost)")
            case .failure:
                // rollback
                status.update(isRepost: repostContext.isReposted, user: user)
                status.update(repostCount: repostContext.repostedCount)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): rollback status repost")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}
