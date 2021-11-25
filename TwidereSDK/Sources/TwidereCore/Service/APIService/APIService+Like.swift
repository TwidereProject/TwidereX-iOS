//
//  APIService+Like.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK

extension APIService {
//    func likeList(
//        count: Int = 200,
//        userID: String,
//        maxID: String? = nil,
//        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
//    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//        let query = Twitter.API.Timeline.TimelineQuery(count: count, userID: userID, maxID: maxID)
//        return Twitter.API.Favorites.list(session: session, authorization: authorization, query: query)
//            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
//                let log = OSLog.api
//                
//                return APIService.Persist.persistTweets(
//                    managedObjectContext: self.backgroundManagedObjectContext,
//                    query: query,
//                    response: response,
//                    persistType: .likeList,
//                    requestTwitterUserID: requestTwitterUserID,
//                    log: log
//                )
//                .setFailureType(to: Error.self)
//                .tryMap { result -> Twitter.Response.Content<[Twitter.Entity.Tweet]> in
//                    switch result {
//                    case .success:
//                        return response
//                    case .failure(let error):
//                        throw error
//                    }
//                }
//                .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .eraseToAnyPublisher()
//    }
}

extension APIService {
    
    /// update status like state
    ///
    /// normal <-> like
    ///
    /// - Parameters:
    ///   - status: target status
    ///   - authenticationContext: `AuthenticationContext`
    public func like(
        status: StatusRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (status, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await like(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await like(
                record: record,
                authenticationContext: authenticationContext
            )
        default:
            assertionFailure()
        }
    }
}

// MARK: - V2
extension APIService {
    
    private struct TwitterLikeContext {
        let statusID: TwitterStatus.ID
        let isLiked: Bool
        let likedCount: Int64
    }
    
    func like(
        record: ManagedObjectRecord<TwitterStatus>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Like.LikeContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update like state and retrieve like context
        let likeContext: TwitterLikeContext = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let status = _status.repost ?? _status
            let isLiked = status.likeBy.contains(me)
            let likedCount = status.likeCount
            let likeCount = isLiked ? likedCount - 1 : likedCount + 1
            status.update(isLike: !isLiked, by: me)
            status.update(likeCount: Int64(max(0, likeCount)))
            let context = TwitterLikeContext(
                statusID: status.id,
                isLiked: isLiked,
                likedCount: likedCount
            )
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status like: \(!isLiked), \(likeCount)")
            return context
        }
        
        // request like or undo like
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Like.LikeContent>, Error>
        do {
            if likeContext.isLiked {
                let response = try await Twitter.API.V2.User.Like.undoLike(
                    session: session,
                    userID: authenticationContext.userID,
                    statusID: likeContext.statusID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let query = Twitter.API.V2.User.Like.LikeQuery(
                    tweetID: likeContext.statusID
                )
                let response = try await Twitter.API.V2.User.Like.like(
                    session: session,
                    query: query,
                    userID: authenticationContext.userID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update like failure: \(error.localizedDescription)")
        }
        
        // update like state
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            let status = _status.repost ?? _status
            
            switch result {
            case .success(let response):
                let isLike = response.value.data.liked
                status.update(isLike: isLike, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status like: \(isLike)")
            case .failure:
                // rollback
                status.update(isLike: likeContext.isLiked, by: me)
                status.update(likeCount: likeContext.likedCount)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): rollback status like")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}

extension APIService {
    
    private struct MastodonLikeContext {
        let statusID: MastodonStatus.ID
        let isLiked: Bool
        let likedCount: Int64
    }
    
    func like(
        record: ManagedObjectRecord<MastodonStatus>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update like state and retrieve like context
        let likeContext: MastodonLikeContext = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let user = authentication.user
            let status = _status.repost ?? _status
            let isLiked = status.likeBy.contains(user)
            let likedCount = status.likeCount
            let likeCount = isLiked ? likedCount - 1 : likedCount + 1
            status.update(isLike: !isLiked, by: user)
            status.update(likeCount: Int64(max(0, likeCount)))
            let context = MastodonLikeContext(
                statusID: status.id,
                isLiked: isLiked,
                likedCount: likedCount
            )
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status like: \(!isLiked), \(likeCount)")
            return context
        }

        // request like or undo like
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>
        do {
            let response = try await Mastodon.API.Favorite.favorites(
                session: session,
                domain: authenticationContext.domain,
                statusID: likeContext.statusID,
                favoriteKind: likeContext.isLiked ? .undo : .do,
                authorization: authenticationContext.authorization
            )
            result = .success(response)
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update like failure: \(error.localizedDescription)")
        }
        
        // update like state
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let _status = record.object(in: managedObjectContext)
            else { return }
            let user = authentication.user
            let status = _status.repost ?? _status
            
            switch result {
            case .success(let response):
                _ = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonStatus.PersistContext(
                        domain: authentication.domain,
                        entity: response.value,
                        me: user,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                if likeContext.isLiked {
                    status.update(likeCount: max(0, status.likeCount - 1))  // undo API return count has delay. Needs -1 local
                }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update status like: \(response.value.favourited.debugDescription)")
            case .failure:
                // rollback
                status.update(isLike: likeContext.isLiked, by: user)
                status.update(likeCount: likeContext.likedCount)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): rollback status like")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}
