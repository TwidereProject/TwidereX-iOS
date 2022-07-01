//
//  NotificationFetchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

public enum NotificationFetchViewModel {

    public enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case mastodon([Mastodon.Entity.Notification])
    }
    
}

extension NotificationFetchViewModel {

    public enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct Output {
        public let result: Result
        public let nextInput: Input?
        
        public var hasMore: Bool {
            nextInput != nil
        }
    }

    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let maxID: Twitter.Entity.Tweet.ID?
        public let count: Int?
        
        public init(authenticationContext: TwitterAuthenticationContext, maxID: Twitter.Entity.Tweet.ID?, count: Int?) {
            self.authenticationContext = authenticationContext
            self.maxID = maxID
            self.count = count
        }
        
        func map(maxID: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                maxID: maxID,
                count: count
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let scope: Mastodon.API.Notification.TimelineScope
        public let maxID: String?
        public let includeTypes: [Mastodon.Entity.Notification.NotificationType]?
        public let excludeTypes: [Mastodon.Entity.Notification.NotificationType]?
        public let limit: Int?

        public init(
            authenticationContext: MastodonAuthenticationContext,
            scope: Mastodon.API.Notification.TimelineScope,
            maxID: String?,
            includeTypes: [Mastodon.Entity.Notification.NotificationType]?,
            excludeTypes: [Mastodon.Entity.Notification.NotificationType]?,
            limit: Int?
        ) {
            self.authenticationContext = authenticationContext
            self.scope = scope
            self.maxID = maxID
            self.includeTypes = includeTypes
            self.excludeTypes = excludeTypes
            self.limit = limit
        }
        
        func map(maxID: String) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                scope: scope,
                maxID: maxID,
                includeTypes: includeTypes,
                excludeTypes: excludeTypes,
                limit: limit
            )
        }
    }
    
    public static func timeline(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
                count: fetchContext.count,
                maxID: fetchContext.maxID
            )
            let response = try await api.twitterMentionTimeline(
                query: query,
                authenticationContext: authenticationContext
            )
            return Output(
                result: .twitter(response.value),
                nextInput: {
                    guard let last = response.value.last else { return nil }
                    let maxID = last.idStr
                    guard maxID != fetchContext.maxID else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return Input.twitter(fetchContext)
                }()
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let query = Mastodon.API.Notification.NotificationsQuery(
                maxID: fetchContext.maxID,
                limit: fetchContext.limit,
                types: fetchContext.includeTypes,
                excludeTypes: fetchContext.excludeTypes,
                accountID: nil
            )
            let response = try await api.mastodonNotificationTimeline(
                query: query,
                scope: fetchContext.scope,
                authenticationContext: authenticationContext
            )
            return Output(
                result: .mastodon(response.value),
                nextInput: {
                    guard let last = response.value.last else { return nil }
                    let maxID = last.id
                    guard maxID != fetchContext.maxID else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return Input.mastodon(fetchContext)
                }()
            )
        }   // end switch input { … }
    }
    
}
