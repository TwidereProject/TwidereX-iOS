//
//  APIService+PublicTimeline.swift
//  
//
//  Created by MainasuK on 2022-1-13.
//

import os.log
import Foundation
import CoreDataStack
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    public func mastodonPublicTimeline(
        local: Bool,
        maxID: Mastodon.Entity.Status.ID? = nil,
        count: Int = 100,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let query = Mastodon.API.Timeline.TimelineQuery(
            local: local,
            remote: nil,
            onlyMedia: nil,
            maxID: maxID,
            sinceID: nil,
            minID: nil,
            limit: count
        )
        
        let response = try await Mastodon.API.Timeline.public(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await persistMastodonTimelineResponse(
            response: response,
            persistContext: TimelinePersistContext(
                kind: local ? .local : .public,
                maxID: maxID,
                authenticationContext: authenticationContext
            )
        )
        return response
    }
}
