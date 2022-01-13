//
//  APIService+Timeline+Mastodon.swift
//  
//
//  Created by MainasuK on 2022-1-13.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension APIService {
    public func mastodonTimeline(
        kind: Feed.Kind,
        maxID: Mastodon.Entity.Status.ID? = nil,
        count: Int = 100,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        switch kind {
        case .home:
            return try await mastodonHomeTimeline(
                maxID: maxID,
                count: count,
                authenticationContext: authenticationContext
            )
        case .local:
            return try await mastodonPublicTimeline(
                local: true,
                maxID: maxID,
                count: count,
                authenticationContext: authenticationContext
            )
        case .public:
            return try await mastodonPublicTimeline(
                local: false,
                maxID: maxID,
                count: count,
                authenticationContext: authenticationContext
            )
        case .notification, .none:
            assertionFailure("Not Supports")
            throw AppError.implicit(.badRequest)
        }
    }
}
