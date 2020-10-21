//
//  APIService+Lookup.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation
import Combine
import TwitterAPI
import CoreDataStack
import CommonOSLog

extension APIService {

    // V2
    func tweets(tweetIDs: [Twitter.Entity.V2.Tweet.ID], authorization: Twitter.API.OAuth.Authorization, twitterUserID: TwitterUser.ID) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Lookup.Content>, Error> {
        return Twitter.API.Lookup.tweets(tweetIDs: tweetIDs, session: session, authorization: authorization)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }
                let content = response.value
//                let dictContent = Twitter.Response.V2.DictContent(content: content)
//
//                let log = OSLog.api
//                let managedObjectContext = self.backgroundManagedObjectContext
//                managedObjectContext.perform {
//                    let _requestTwitterUser: TwitterUser? = {
//                        let request = TwitterUser.sortedFetchRequest
//                        request.predicate = TwitterUser.predicate(idStr: twitterUserID)
//                        request.fetchLimit = 1
//                        request.returnsObjectsAsFaults = false
//                        do {
//                            return try managedObjectContext.fetch(request).first
//                        } catch {
//                            assertionFailure(error.localizedDescription)
//                            return nil
//                        }
//                    }()
//
//                    for tweet in dictContent.tweetDict {
//
//                    }
//
//                }
            })
            .eraseToAnyPublisher()
            
    }
    
}
