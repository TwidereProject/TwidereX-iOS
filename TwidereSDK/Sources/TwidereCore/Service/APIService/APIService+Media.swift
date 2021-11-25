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
    
    func mediaInit(
        totalBytes: Int,
        mediaType: String,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.InitResponse>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Media.InitQuery(totalBytes: totalBytes, mediaType: mediaType)
        return Twitter.API.Media.`init`(session: session, authorization: authorization, query: query)
    }
    
    func mediaAppend(
        mediaID: String,
        chunk: Data,
        index: Int,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.AppendResponse>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let mediaData = chunk.base64EncodedString()
        let query = Twitter.API.Media.AppendQuery(mediaID: mediaID, segmentIndex: index)
        return Twitter.API.Media.append(session: session, authorization: authorization, query: query, mediaData: mediaData)
    }
    
    func mediaFinalize(
        mediaID: String,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.FinalizeResponse>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Media.FinalizeQuery(mediaID: mediaID)
        return Twitter.API.Media.finalize(session: session, authorization: authorization, query: query)
    }
    
    func mediaStatus(
        mediaID: String,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.StatusResponse>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Media.StatusQuery(mediaID: mediaID)
        return Twitter.API.Media.status(session: session, authorization: authorization, query: query)
    }
}
