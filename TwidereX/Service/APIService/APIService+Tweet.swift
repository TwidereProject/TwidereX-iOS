//
//  APIService+Tweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterAPI
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    func tweet(
        content: String,
        mediaIDs: [String]?,
        placeID: String?,
        replyToTweetObjectID: NSManagedObjectID?,
        excludeReplyUserIDs: [TwitterUser.ID]?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let managedObjectContext = backgroundManagedObjectContext
        
        let mediaIDs: String? = mediaIDs?.joined(separator: ",")
        let excludeReplyUserIDs: String? = excludeReplyUserIDs?.joined(separator: ",")
        let query = Future<Twitter.API.Statuses.UpdateQuery, Never> { promise in
            if let replyToTweetObjectID = replyToTweetObjectID {
                managedObjectContext.perform {
                    let replyTo = managedObjectContext.object(with: replyToTweetObjectID) as! Tweet
                    let query = Twitter.API.Statuses.UpdateQuery(
                        status: content,
                        inReplyToStatusID: replyTo.id,
                        autoPopulateReplyMetadata: true,
                        excludeReplyUserIDs: excludeReplyUserIDs,
                        mediaIDs: mediaIDs,
                        latitude: nil,
                        longitude: nil,
                        placeID: placeID
                    )
                    DispatchQueue.main.async {
                        promise(.success(query))
                    }
                }
            } else {
                let query = Twitter.API.Statuses.UpdateQuery(
                    status: content,
                    inReplyToStatusID: nil,
                    autoPopulateReplyMetadata: false,
                    excludeReplyUserIDs: excludeReplyUserIDs,
                    mediaIDs: mediaIDs,
                    latitude: nil,
                    longitude: nil,
                    placeID: placeID
                )
                promise(.success(query))
            }
        }

        return query
            .setFailureType(to: Error.self)
            .map { query in return Twitter.API.Statuses.update(session: self.session, authorization: authorization, query: query) }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}
