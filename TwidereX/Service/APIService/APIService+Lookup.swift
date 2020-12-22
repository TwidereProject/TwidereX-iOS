//
//  APIService+Lookup.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import os.log
import Foundation
import Combine
import TwitterAPI
import CoreDataStack
import CommonOSLog

extension APIService {
    
    // V1
    func statuses(
        tweetIDs: [Twitter.Entity.Tweet.ID],
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Lookup.Query(ids: tweetIDs)
        return Twitter.API.Lookup.tweets(session: session, authorization: authorization, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
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
                        _ = APIService.CoreData.createOrMergeTweet(
                            into: managedObjectContext,
                            for: requestTwitterUser,
                            entity: entity,
                            networkDate: response.networkDate,
                            log: log
                        )
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
    

    // V2
    func tweets(
        tweetIDs: [Twitter.Entity.V2.Tweet.ID],
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Lookup.Content>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        return Twitter.API.V2.Lookup.tweets(tweetIDs: tweetIDs, session: session, authorization: authorization)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Lookup.Content>, Error> in
                let log = OSLog.api
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: [response.data, response.includes?.tweets].compactMap { $0 }.flatMap { $0 },
                        users: response.includes?.users ?? [],
                        media: response.includes?.media ?? []
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
