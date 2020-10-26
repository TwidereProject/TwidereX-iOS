//
//  APIService+Media.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterAPI
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    func mediaInit(
        totalBytes: Int,
        mediaType: String,
        authorization: Twitter.API.OAuth.Authorization
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.InitResponse>, Error> {
        let query = Twitter.API.Media.InitQuery(totalBytes: totalBytes, mediaType: mediaType)
        return Twitter.API.Media.`init`(session: session, authorization: authorization, query: query)
    }
    
    func mediaAppend(
        mediaID: String,
        chunk: Data,
        index: Int,
        authorization: Twitter.API.OAuth.Authorization
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.Media.AppendResponse>, Error> {
        let mediaData = chunk.base64EncodedString()
        let query = Twitter.API.Media.AppendQuery(mediaID: mediaID, segmentIndex: index)
        return Twitter.API.Media.append(session: session, authorization: authorization, query: query, mediaData: mediaData)
    }
    
}
