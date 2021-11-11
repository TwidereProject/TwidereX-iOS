//
//  NotificationListFetchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

enum NotificationListFetchViewModel {
    
    enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
//        case mastodon([Mastodon.Entity.Notification])
    }
    
}

extension NotificationListFetchViewModel {

    enum NotificationInput {
        case twitter(TwitterMentionsFetchContext)
        // case mastodon(MastodonNotificationFetchContext)
    }
    
    struct NotificationOutput {
        let result: Result
        let nextInput: NotificationInput?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }

    struct TwitterMentionsFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let maxID: String?
        let count: Int?
        
        func map(maxID: String) -> TwitterMentionsFetchContext {
            return TwitterMentionsFetchContext(
                authenticationContext: authenticationContext,
                maxID: maxID,
                count: count
            )
        }
    }
    
//    struct MastodonNotificationFetchContext {
//        let authenticationContext: MastodonAuthenticationContext
//        let maxID: String?
//        let count: Int?
//
//        func map(maxID: String) -> TwitterMentionsFetchContext {
//            return TwitterMentionsFetchContext(
//                authenticationContext: authenticationContext,
//                maxID: maxID,
//                count: count
//            )
//        }
//    }
    
    static func notificationTimeline(context: AppContext, input: NotificationInput) async throws -> NotificationOutput {
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
            return NotificationOutput(
                result: .twitter(response.value),
                nextInput: {
                    guard let last = response.value.last else { return nil }
                    let maxID = last.idStr
                    guard maxID != fetchContext.maxID else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return NotificationInput.twitter(fetchContext)
                }()
            )
        }
    }
    
}
