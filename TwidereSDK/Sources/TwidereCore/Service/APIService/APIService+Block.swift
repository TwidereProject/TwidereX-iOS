//
//  APIService+Block.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {

    public func block(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await block(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await block(
                record: record,
                authenticationContext: authenticationContext
            )
        default:
            break
        }
    }

}

extension APIService {
    
    private struct TwitterBlockContext {
        let sourceUserID: TwitterUser.ID
        let targetUserID: TwitterUser.ID
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    func block(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Block.BlockContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let blockContext: TwitterBlockContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isBlocking = user.blockingBy.contains(me)
            let isFollowing = user.followingBy.contains(me)
            // toggle block state
            user.update(isBlock: !isBlocking, by: me)
            // update follow state implicitly
            if !isBlocking {
                // will do block action. set to unfollow
                user.update(isFollow: false, by: me)
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) block state: \(!isBlocking)")
            return TwitterBlockContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isBlocking: isBlocking,
                isFollowing: isFollowing
            )
        }
        
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Block.BlockContent>, Error>
        do {
            if blockContext.isBlocking {
                let response = try await Twitter.API.V2.User.Block.unblock(
                    session: session,
                    sourceUserID: blockContext.sourceUserID,
                    targetUserID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Twitter.API.V2.User.Block.block(
                    session: session,
                    sourceUserID: blockContext.sourceUserID,
                    query: Twitter.API.V2.User.Block.BlockQuery(targetUserID: blockContext.targetUserID),
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let isBlocking = response.value.data.blocking
                user.update(isBlock: isBlocking, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state: \(isBlocking)")
            case .failure:
                // rollback
                user.update(isBlock: blockContext.isBlocking, by: me)
                user.update(isFollow: blockContext.isFollowing, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state")
            }
        }

        let response = try result.get()
        return response
    }
    
}

extension APIService {
    
    private struct MastodonBlockContext {
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    func block(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let blockContext: MastodonBlockContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isBlocking = user.blockingBy.contains(me)
            let isFollowing = user.followingBy.contains(me)
            // toggle block state
            user.update(isBlock: !isBlocking, by: me)
            // update follow state implicitly
            if !isBlocking {
                // will do block action. set to unfollow
                user.update(isFollow: false, by: me)
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) block state: \(!isBlocking)")
            return MastodonBlockContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isBlocking: isBlocking,
                isFollowing: isFollowing
            )
        }
        
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if blockContext.isBlocking {
                let response = try await Mastodon.API.Account.unblock(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.block(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let relationship = response.value
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state: \(relationship.blocking)")
            case .failure:
                // rollback
                user.update(isBlock: blockContext.isBlocking, by: me)
                user.update(isFollow: blockContext.isFollowing, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}

extension APIService {
    @available(*, deprecated, message: "")
    func toggleBlock(
        for twitterUser: TwitterUser,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        return blockUpdateLocal(
            twitterUserObjectID: twitterUser.objectID,
            twitterAuthenticationBox: activeTwitterAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            impactFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            impactFeedbackGenerator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local block state update fail", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                assertionFailure(error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local block state update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
        .map { blockUpdateQueryKind, targetTwitterUserID in
            self.blockUpdateRemote(
                blockUpdateQueryKind: blockUpdateQueryKind,
                twitterUserID: targetTwitterUserID,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Block] remote mute update fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                
                if let responseError = error as? Twitter.API.Error.ResponseError,
                   let twitterAPIError = responseError.twitterAPIError {
                    switch twitterAPIError {
                    case .accountIsTemporarilyLocked, .rateLimitExceeded, .blockedFromRequestFollowingThisUser:
                        self.error.send(.explicit(.twitterResponseError(responseError)))
                    default:
                        break
                    }
                }
                
                // rollback
                self.blockUpdateLocal(
                    twitterUserObjectID: twitterUser.objectID,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
                .sink { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Block] rollback finish", ((#file as NSString).lastPathComponent), #line, #function)
                } receiveValue: { _ in
                    // do nothing
                    notificationFeedbackGenerator.prepare()
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
                .store(in: &self.disposeBag)
                
                
            case .finished:
                notificationFeedbackGenerator.notificationOccurred(.success)
                os_log("%{public}s[%{public}ld], %{public}s: [Block] remote mute update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        })
        .eraseToAnyPublisher()
    }
    
}

extension APIService {
    
    // update database local and return query update type for remote request
    @available(*, deprecated, message: "")
    func blockUpdateLocal(
        twitterUserObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<(Twitter.API.Block.BlockUpdateQuery.QueryKind, TwitterUser.ID), Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        var _targetTwitterUserID: TwitterUser.ID?
        var _queryType: Twitter.API.Block.BlockUpdateQuery.QueryKind?
        let managedObjectContext = backgroundManagedObjectContext
        
        return managedObjectContext.performChanges {
            let _requestTwitterUser: TwitterUser? = {
                let request = TwitterUser.sortedFetchRequest
                request.predicate = TwitterUser.predicate(idStr: requestTwitterUserID)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
            guard let requestTwitterUser = _requestTwitterUser else {
                assertionFailure()
                return
            }
            
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            _targetTwitterUserID = twitterUser.id
            
            let isBlocking = (twitterUser.blockingBy ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            if isBlocking {
                _queryType = .destroy
            } else {
                _queryType = .create
            }
//            twitterUser.update(blocking: !isBlocking, by: requestTwitterUser)
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetTwitterUserID = _targetTwitterUserID,
                      let queryType = _queryType else {
                    throw AppError.implicit(.badRequest)
                }
                return (queryType, targetTwitterUserID)
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    @available(*, deprecated, message: "")
    func blockUpdateRemote(
        blockUpdateQueryKind: Twitter.API.Block.BlockUpdateQuery.QueryKind,
        twitterUserID: TwitterUser.ID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        
        let query = Twitter.API.Block.BlockUpdateQuery(
            userID: twitterUserID,
            queryKind: blockUpdateQueryKind
        )
        return Twitter.API.Block.block(
            session: session,
            authorization: authorization,
            query: query
        )
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                if let responseError = error as? Twitter.API.Error.ResponseError {
                    switch responseError.twitterAPIError {
                    case .accountIsTemporarilyLocked, .rateLimitExceeded:
                        self.error.send(.explicit(.twitterResponseError(responseError)))
                    default:
                        break
                    }
                }
            case .finished:
                switch blockUpdateQueryKind {
                case .create:
                    // destroy following friendship
                    let managedObjectContext = self.backgroundManagedObjectContext
                    managedObjectContext.performChanges {
                        let _requestTwitterUser: TwitterUser? = {
                            let request = TwitterUser.sortedFetchRequest
                            request.predicate = TwitterUser.predicate(idStr: requestTwitterUserID)
                            request.fetchLimit = 1
                            request.returnsObjectsAsFaults = false
                            do {
                                return try managedObjectContext.fetch(request).first
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return nil
                            }
                        }()
                        
                        guard let requestTwitterUser = _requestTwitterUser else {
                            assertionFailure()
                            return
                        }
                        
                        let _twitterUser: TwitterUser? = {
                            let request = TwitterUser.sortedFetchRequest
                            request.predicate = TwitterUser.predicate(idStr: twitterUserID)
                            request.fetchLimit = 1
                            request.returnsObjectsAsFaults = false
                            do {
                                return try managedObjectContext.fetch(request).first
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return nil
                            }
                        }()
                        
                        guard let twitterUser = _twitterUser else {
                            assertionFailure()
                            return
                        }
//                        twitterUser.update(following: false, by: requestTwitterUser)
//                        twitterUser.update(followRequestSent: false, from: requestTwitterUser)
                    }
                    .sink { _ in
                        // do nothing
                    }
                    .store(in: &self.disposeBag)
                case .destroy:
                    break
                }
            }
        })
        .eraseToAnyPublisher()
    }
    
}
