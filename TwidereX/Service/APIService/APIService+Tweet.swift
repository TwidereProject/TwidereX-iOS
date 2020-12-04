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
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let managedObjectContext = backgroundManagedObjectContext
        let query = Future<Twitter.API.Statuses.UpdateQuery, Never> { promise in
            guard let replyToTweetObjectID = replyToTweetObjectID else {
                let query = Twitter.API.Statuses.UpdateQuery(
                    status: content,
                    inReplyToStatusID: nil,
                    autoPopulateReplyMetadata: false,
                    mediaIDs: mediaIDs?.joined(separator: ","),
                    latitude: nil,
                    longitude: nil,
                    placeID: placeID
                )
                promise(.success(query))
                return
            }
            
            managedObjectContext.perform {
                let replyTo = managedObjectContext.object(with: replyToTweetObjectID) as! Tweet
                let query = Twitter.API.Statuses.UpdateQuery(
                    status: content,
                    inReplyToStatusID: replyTo.id,
                    autoPopulateReplyMetadata: true,
                    mediaIDs: nil,
                    latitude: nil,
                    longitude: nil,
                    placeID: nil
                )
                DispatchQueue.main.async {
                    promise(.success(query))
                }
            }
        }

        return query
            .setFailureType(to: Error.self)
            .map { query in return Twitter.API.Statuses.update(session: self.session, authorization: authorization, query: query) }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}
