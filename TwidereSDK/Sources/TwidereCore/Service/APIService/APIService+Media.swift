//
//  APIService+Media.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    public func mediaInit(
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
    
    public func mediaAppend(
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
    
    public func mediaFinalize(
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
    
    public func mediaStatus(
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
