//
//  APIService+Status+Publish.swift
//
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func publishTwitterStatus(
        content: String,
        mediaIDs: [String]?,
        placeID: String?,
        replyTo: ManagedObjectRecord<TwitterStatus>?,
        excludeReplyUserIDs: [TwitterUser.ID]?,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.Tweet> {
        let authorization = twitterAuthenticationContext.authorization
        let managedObjectContext = backgroundManagedObjectContext

        let mediaIDs: String? = mediaIDs?.joined(separator: ",")
        let excludeReplyUserIDs: String? = excludeReplyUserIDs?.joined(separator: ",")
        
        let replyToID: Twitter.Entity.V2.Tweet.ID? = await managedObjectContext.perform {
            guard let replyTo = replyTo?.object(in: managedObjectContext) else { return nil }
            return replyTo.id
        }
        
        let query = Twitter.API.Statuses.UpdateQuery(
            status: content,
            inReplyToStatusID: replyToID,
            autoPopulateReplyMetadata: replyToID != nil,
            excludeReplyUserIDs: excludeReplyUserIDs,
            mediaIDs: mediaIDs,
            latitude: nil,
            longitude: nil,
            placeID: placeID
        )
        
        let response = try await Twitter.API.Statuses.update(
            session: session,
            query: query,
            authorization: authorization
        )
        
        return response
    }
    
}

extension APIService {
    
    public func publishMastodonStatus(
        query: Mastodon.API.Status.PublishStatusQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        
        let response = try await Mastodon.API.Status.publish(
            session: session,
            domain: domain,
            idempotencyKey: nil,    // TODO:
            query: query,
            authorization: authorization
        )
        
        return response
    }
    
}
