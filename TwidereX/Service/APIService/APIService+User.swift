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
    
    func userSearch(searchText: String, page: Int, count: Int = 20, twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.User]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Users.SearchQuery(
            q: searchText,
            page: page,
            count: count
        )
        return Twitter.API.Users.search(session: session, authorization: authorization, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.User]>, Error> in
                let log = OSLog.api
        
                let entities = response.value
                let managedObjectContext = self.backgroundManagedObjectContext
                
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
                    
                    for entity in entities {
                        _ = APIService.CoreData.createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity, userCache: nil, networkDate: response.networkDate, log: log)
                    }
                }
                .map { _ in return response }
                .replaceError(with: response)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
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
                        twitterUser.update(blocking: true, by: requestTwitterUser)
                        twitterUser.update(following: false, by: requestTwitterUser)
                        twitterUser.update(followRequestSent: false, from: requestTwitterUser)
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
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        return Twitter.API.V2.UserLookup.users(userIDs: userIDs, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [],
                        users: response.data ?? [],
                        media: [],
                        places: []
                    )
                }
                
                // persist data
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in return response }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func users(
        usernames: [String],
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        return Twitter.API.V2.UserLookup.users(usernames: usernames, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [],
                        users: response.data ?? [],
                        media: [],
                        places: []
                    )
                }
                
                // persist data
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in return response }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

}
