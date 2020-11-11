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
import TwitterAPI
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
                        _ = APIService.CoreData.createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity, networkDate: response.networkDate, log: log)
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
    
}
