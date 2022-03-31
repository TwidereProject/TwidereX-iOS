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
    
    public struct PublishStatusContext {
        public let content: String
        public let mastodonVisibility: Mastodon.Entity.Status.Visibility?
        public let idempotencyKey: String?
        
        public init(
            content: String,
            mastodonVisibility: Mastodon.Entity.Status.Visibility?,
            idempotencyKey: String?
        ) {
            self.content = content
            self.mastodonVisibility = mastodonVisibility
            self.idempotencyKey = idempotencyKey
        }
    }
    
    public struct PublishStatusResponse {
        public let id: String
        public let authorName: String
        public let authorUsername: String
        public let authorAvatarURL: URL?
        public let statusURL: URL
    }

    public func publishStatus(
        context: PublishStatusContext,
        authenticationContext: AuthenticationContext
    ) async throws -> PublishStatusResponse {
        switch authenticationContext {
        case .twitter(let authenticationContext):
            let response = try await publishTwitterStatus(
                content: context.content,
                mediaIDs: nil,
                placeID: nil,
                replyTo: nil,
                excludeReplyUserIDs: nil,
                twitterAuthenticationContext: authenticationContext
            )
            return .init(
                id: response.value.idStr,
                authorName: response.value.user.name,
                authorUsername: response.value.user.screenName,
                authorAvatarURL: response.value.user.avatarImageURL(),
                statusURL: response.value.statusURL
            )
        case .mastodon(let authenticationContext):
            let response = try await publishMastodonStatus(
                query: Mastodon.API.Status.PublishStatusQuery(
                    status: context.content,
                    mediaIDs: nil,
                    pollOptions: nil,
                    pollExpiresIn: nil,
                    pollMultiple: nil,
                    inReplyToID: nil,
                    sensitive: nil,
                    spoilerText: nil,
                    visibility: context.mastodonVisibility,
                    idempotencyKey: context.idempotencyKey
                ),
                mastodonAuthenticationContext: authenticationContext
            )
            return .init(
                id: response.value.id,
                authorName: response.value.account.name,
                authorUsername: response.value.account.acctWithDomain(domain: authenticationContext.domain),
                authorAvatarURL: URL(string: response.value.account.avatar),
                statusURL: URL(string: response.value.url ?? response.value.uri)!
            )
        }   // end switch
    }   // end func
    
}

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
            query: query,
            authorization: authorization
        )
        
        return response
    }
    
}
