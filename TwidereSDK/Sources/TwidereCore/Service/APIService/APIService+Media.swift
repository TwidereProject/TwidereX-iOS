//
//  APIService+Media.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import TwitterSDK
import MastodonSDK

// MARK: - Twitter
extension APIService {
    
    public func twitterMediaInit(
        totalBytes: Int,
        mediaType: String,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.Media.InitResponse> {
        let authorization = twitterAuthenticationContext.authorization
        let query = Twitter.API.Media.InitQuery(totalBytes: totalBytes, mediaType: mediaType)
        return try await Twitter.API.Media.`init`(
            session: session,
            query: query,
            authorization: authorization
        )
    }
    
    public func twitterMediaAppend(
        mediaID: String,
        chunk: Data,
        index: Int,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.Media.AppendResponse> {
        let authorization = twitterAuthenticationContext.authorization
        let mediaData = chunk.base64EncodedString()
        let query = Twitter.API.Media.AppendQuery(mediaID: mediaID, mediaData: mediaData, segmentIndex: index)
        return try await Twitter.API.Media.append(
            session: session,
            query: query,
            authorization: authorization
        )
    }
    
    public func TwitterMediaFinalize(
        mediaID: String,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.Media.FinalizeResponse> {
        let authorization = twitterAuthenticationContext.authorization
        let query = Twitter.API.Media.FinalizeQuery(mediaID: mediaID)
        return try await Twitter.API.Media.finalize(
            session: session,
            query: query,
            authorization: authorization
        )
    }
    
    public func twitterMediaStatus(
        mediaID: String,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.Media.StatusResponse> {
        let authorization = twitterAuthenticationContext.authorization
        let query = Twitter.API.Media.StatusQuery(mediaID: mediaID)
        return try await Twitter.API.Media.status(
            session: session,
            query: query,
            authorization: authorization
        )
    }
    
}

// MARK: - Mastodon

extension APIService {

    public func mastodonMediaUpload(
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext,
        needsFallback: Bool
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        if needsFallback {
            return try await uploadMediaV1(query: query, mastodonAuthenticationContext: mastodonAuthenticationContext)
        } else {
            return try await uploadMediaV2(query: query, mastodonAuthenticationContext: mastodonAuthenticationContext)
        }
    }
 
    private func uploadMediaV1(
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        return try await Mastodon.API.Media.uploadMedia(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }

    private func uploadMediaV2(
        query: Mastodon.API.Media.UploadMediaQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        return try await Mastodon.API.V2.Media.uploadMedia(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        )
    }

    public func mastodonMediaAttachment(
        attachmentID: Mastodon.Entity.Attachment.ID,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        return try await Mastodon.API.Media.getMedia(
            session: session,
            domain: domain,
            attachmentID: attachmentID,
            authorization: authorization
        )
    }
    
    public func mastodonMediaUpdate(
        attachmentID: Mastodon.Entity.Attachment.ID,
        query: Mastodon.API.Media.UpdateMediaQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        return try await Mastodon.API.Media.updateMedia(
            session: session,
            domain: domain,
            attachmentID: attachmentID,
            query: query,
            authorization: authorization
        )
    }
    
}

