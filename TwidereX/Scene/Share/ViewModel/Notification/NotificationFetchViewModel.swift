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

enum NotificationFetchViewModel {
    
    enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case mastodon([Mastodon.Entity.Notification])
    }
    
}

extension NotificationFetchViewModel {

    enum Input {
        case twitter(TwitterFetchContext)
         case mastodon(MastodonFetchContext)
    }
    
    struct Output {
        let result: Result
        let nextInput: Input?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }

    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let maxID: Twitter.Entity.Tweet.ID?
        let count: Int?
        
        func map(maxID: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                maxID: maxID,
                count: count
            )
        }
    }
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let maxID: String?
        let excludeTypes: [Mastodon.Entity.Notification.NotificationType]?

        let limit: Int?

        func map(maxID: String) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                maxID: maxID,
                excludeTypes: excludeTypes,
                limit: limit
            )
        }
    }
    
    static func timeline(context: AppContext, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
                count: fetchContext.count,
                maxID: fetchContext.maxID
            )
            let response = try await context.apiService.twitterMentionTimeline(
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
                excludeTypes: fetchContext.excludeTypes,
                accountID: nil
            )
            let response = try await context.apiService.mastodonNotificationTimeline(
                query: query,
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
