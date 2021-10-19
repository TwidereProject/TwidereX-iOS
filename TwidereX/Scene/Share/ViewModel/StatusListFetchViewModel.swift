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
            
            var count: Int {
                switch self {
                case .twitter(let context):     return context.count ?? 100
                case .mastodon(let context):    return context.count ?? 100
                }
            }
        }
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let maxID: TwitterStatus.ID?
        let count: Int?
        let excludeReplies: Bool
        let userIdentifier: TwitterUserIdentifier?
    }
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let maxID: MastodonStatus.ID?
        let count: Int?
        let excludeReplies: Bool
        let excludeReblogs: Bool
        let onlyMedia: Bool
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
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await context.apiService.twitterHomeTimeline(
                maxID: fetchContext.maxID,
                count: fetchContext.count ?? 100,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.idStr else { return nil }
                let fetchContext = TwitterFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    userIdentifier: fetchContext.userIdentifier
                )
                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await context.apiService.mastodonHomeTimeline(
                maxID: fetchContext.maxID,
                count: fetchContext.count ?? 100,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = MastodonFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    excludeReblogs: fetchContext.excludeReblogs,
                    onlyMedia: fetchContext.onlyMedia,
                    userIdentifier: fetchContext.userIdentifier
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
        case .twitter(let fetchContext):
            guard let userID = fetchContext.userIdentifier?.id else {
                throw APIService.APIError.implicit(.badRequest)
            }
            let query = Twitter.API.Statuses.TimelineQuery(
                count: fetchContext.count ?? 100,
                userID: userID,
                maxID: fetchContext.maxID,
                excludeReplies: fetchContext.excludeReplies
            )
            let authenticationContext = fetchContext.authenticationContext
            let response = try await context.apiService.twitterUserTimeline(
                query: query,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.idStr else { return nil }
                let fetchContext = TwitterFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    userIdentifier: fetchContext.userIdentifier
                )
                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let fetchContext):
            guard let accountID = fetchContext.userIdentifier?.id else {
                throw APIService.APIError.implicit(.badRequest)
            }
            let authenticationContext = fetchContext.authenticationContext
            let query = Mastodon.API.Account.AccountStatusesQuery(
                maxID: fetchContext.maxID,
                sinceID: nil,
                excludeReplies: fetchContext.excludeReplies,
                excludeReblogs: fetchContext.excludeReblogs,
                onlyMedia: fetchContext.onlyMedia,
                limit: fetchContext.count ?? 100
            )
            let response = try await context.apiService.mastodonUserTimeline(
                accountID: accountID,
                query: query,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = MastodonFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    excludeReblogs: fetchContext.excludeReblogs,
                    onlyMedia: fetchContext.onlyMedia,
                    userIdentifier: fetchContext.userIdentifier
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
    
    static func likeTimeline(context: AppContext, input: Input) async throws -> Output {
        switch input.fetchContext {
        case .twitter(let fetchContext):
            guard let userID = fetchContext.userIdentifier?.id else {
                throw APIService.APIError.implicit(.badRequest)
            }
            let authenticationContext = fetchContext.authenticationContext
            let query = Twitter.API.Statuses.TimelineQuery(
                count: fetchContext.count ?? 100,
                userID: userID,
                maxID: fetchContext.maxID
            )
            let response = try await context.apiService.twitterLikeTimeline(
                query: query,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.idStr else { return nil }
                let fetchContext = TwitterFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    userIdentifier: fetchContext.userIdentifier
                )
                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let query = Mastodon.API.Favorite.FavoriteStatusesQuery(
                limit: fetchContext.count ?? 100,
                maxID: fetchContext.maxID
            )
            let response = try await context.apiService.mastodonLikeTimeline(
                query: query,
                authenticationContext: authenticationContext
            )
            let noMore = response.link?.maxID == nil
            let nextInput: Input? = {
                guard let maxID = response.link?.maxID else { return nil }
                let fetchContext = MastodonFetchContext(
                    authenticationContext: authenticationContext,
                    maxID: maxID,
                    count: fetchContext.count,
                    excludeReplies: fetchContext.excludeReplies,
                    excludeReblogs: fetchContext.excludeReblogs,
                    onlyMedia: fetchContext.onlyMedia,
                    userIdentifier: fetchContext.userIdentifier
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
}