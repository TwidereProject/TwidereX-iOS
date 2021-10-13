//
//  StatusListFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

enum StatusListFetchViewModel {
    struct Input {
        let context: AppContext
        let fetchContext: FetchContext
    }
    
    enum FetchContext {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let maxID: TwitterStatus.ID?
        let userIdentifier: TwitterUserIdentifier?
    }
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let maxID: MastodonStatus.ID?
        let userIdentifier: MastodonUserIdentifier?
    }
    
    struct Output {
        let result: Result
        let hasMore: Bool

        enum Result {
            case twitter([Twitter.Entity.Tweet])       // v1
            case mastodon([Mastodon.Entity.Status])
        }
    }
}

extension StatusListFetchViewModel {
    static func homeTimeline(input: Input) async throws -> Output {
        let context = input.context
    
        switch input.fetchContext {
        case .twitter(let twitterFetchContext):
            let authenticationContext = twitterFetchContext.authenticationContext
            let response = try await context.apiService.twitterHomeTimeline(
                maxID: twitterFetchContext.maxID,
                authenticationContext: authenticationContext
            )
            let notHasMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == twitterFetchContext.maxID)
            return Output(
                result: .twitter(response.value),
                hasMore: !notHasMore
            )
        case .mastodon(let mastodonFetchContext):
            let authenticationContext = mastodonFetchContext.authenticationContext
            let response = try await context.apiService.mastodonHomeTimeline(
                maxID: mastodonFetchContext.maxID,
                authenticationContext: authenticationContext
            )
            let notHasMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == mastodonFetchContext.maxID)
            return Output(
                result: .mastodon(response.value),
                hasMore: !notHasMore
            )
        }
    }
    
    static func userTimeline(input: Input) async throws -> Output {
        let context = input.context
        
        switch input.fetchContext {
        case .twitter(let twitterFetchContext):
            guard let userID = twitterFetchContext.userIdentifier?.id else {
                throw APIService.APIError.implicit(.badRequest)
            }
            let query = Twitter.API.Timeline.TimelineQuery(
                count: 20, // APIService.userTimelineRequestFetchLimit,
                userID: userID,
                maxID: twitterFetchContext.maxID,
                excludeReplies: false
            )
            let authenticationContext = twitterFetchContext.authenticationContext
            let response = try await context.apiService.twitterUserTimeline(
                query: query,
                authenticationContext: authenticationContext
            )
            let notHasMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == twitterFetchContext.maxID)
            return Output(
                result: .twitter(response.value),
                hasMore: !notHasMore
            )
        case .mastodon(let mastodonFetchContext):
            fatalError("TODO")
//            let authenticationContext = mastodonFetchContext.authenticationContext
//            let response = try await context.apiService.mastodonHomeTimeline(
//                maxID: mastodonFetchContext.maxID,
//                authenticationContext: authenticationContext
//            )
//            let notHasMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == mastodonFetchContext.maxID)
//            return Output(
//                result: .mastodon(response.value),
//                hasMore: !notHasMore
//            )
        }
    }
}
