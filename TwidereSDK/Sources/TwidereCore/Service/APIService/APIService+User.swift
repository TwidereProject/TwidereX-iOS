//
//  APIService+User.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    func userReportForSpam(
        twitterUserID: Twitter.Entity.User.ID,
        performBlock: Bool,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Users.ReportSpamQuery(
            userID: twitterUserID,
            performBlock: performBlock
        )
        return Twitter.API.Users.reportSpam(
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
                if performBlock {
                    // set blocking and remove following friendship
                    // see: APIService+Block
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
//                        twitterUser.update(blocking: true, by: requestTwitterUser)
//                        twitterUser.update(following: false, by: requestTwitterUser)
//                        twitterUser.update(followRequestSent: false, from: requestTwitterUser)
                    }
                    .sink { _ in
                        // do nothing
                    }
                    .store(in: &self.disposeBag)
                }
            }
        })
        .eraseToAnyPublisher()
    }
    
}

// V2
extension APIService {

    func users(
        userIDs: [Twitter.Entity.User.ID],
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> {
        fatalError()
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//        return Twitter.API.V2.UserLookup.users(userIDs: userIDs, session: session, authorization: authorization)
//            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> in
//                let log = OSLog.api
//
//                let dictResponse = response.map { response in
//                    return Twitter.Response.V2.DictContent(
//                        tweets: [],
//                        users: response.data ?? [],
//                        media: [],
//                        places: []
//                    )
//                }
//
//                // persist data
//                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
//                    .map { _ in return response }
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .eraseToAnyPublisher()
    }
    
    public func users(
        usernames: [String],
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.UserLookup.Content> {
        let authorization = twitterAuthenticationContext.authorization
        let response = try await Twitter.API.V2.UserLookup.users(
            session: session,
            usernames: usernames,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = twitterAuthenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for user in response.value.data ?? [] {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: user,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }

}
