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
        let fetchContext: FetchContext
        
        enum FetchContext {
            case twitter(TwitterFetchContext)
            case mastodon(MastodonFetchContext)
        }
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
        let nextInput: Input?

        enum Result {
            case twitter([Twitter.Entity.Tweet])       // v1
            case mastodon([Mastodon.Entity.Status])
        }
    }
}

extension StatusListFetchViewModel {
    static func homeTimeline(context: AppContext, input: Input) async throws -> Output {    
        switch input.fetchContext {
        case .twitter(let twitterFetchContext):
            let authenticationContext = twitterFetchContext.authenticationContext
            let response = try await context.apiService.twitterHomeTimeline(
                maxID: twitterFetchContext.maxID,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == twitterFetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.idStr else { return nil }
                let fetchContext = TwitterFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    userIdentifier: twitterFetchContext.userIdentifier
                )
                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let mastodonFetchContext):
            let authenticationContext = mastodonFetchContext.authenticationContext
            let response = try await context.apiService.mastodonHomeTimeline(
                maxID: mastodonFetchContext.maxID,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == mastodonFetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = MastodonFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    userIdentifier: mastodonFetchContext.userIdentifier
                )
                return Input(fetchContext: .mastodon(fetchContext))
            }()
            return Output(
                result: .mastodon(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        }
    }
    
    static func userTimeline(context: AppContext, input: Input) async throws -> Output {
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
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == twitterFetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.idStr else { return nil }
                let fetchContext = TwitterFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    userIdentifier: twitterFetchContext.userIdentifier
                )
                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
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
