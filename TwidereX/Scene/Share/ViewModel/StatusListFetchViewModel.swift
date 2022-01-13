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
import TwidereCore

enum StatusListFetchViewModel {
    
    enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case twitterV2([Twitter.Entity.V2.Tweet]) // v2
        case mastodon([Mastodon.Entity.Status])
    }
    
}

extension StatusListFetchViewModel {
    @available(*, deprecated, message: "")
    struct Input {
        let fetchContext: FetchContext
        
        // TODO: refactor this with protocol and more specific case
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
    
    @available(*, deprecated, message: "")
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let searchText: String?
        let maxID: TwitterStatus.ID?
        let nextToken: String?
        let count: Int?
        let excludeReplies: Bool
        let onlyMedia: Bool
        let userIdentifier: TwitterUserIdentifier?
        
        func map(maxID: TwitterStatus.ID?) -> TwitterFetchContext {
            TwitterFetchContext(
                authenticationContext: self.authenticationContext,
                searchText: self.searchText,
                maxID: maxID,
                nextToken: self.nextToken,
                count: self.count,
                excludeReplies: self.excludeReplies,
                onlyMedia: self.onlyMedia,
                userIdentifier: self.userIdentifier
            )
        }
        
        func map(nextToken: String?) -> TwitterFetchContext {
            TwitterFetchContext(
                authenticationContext: self.authenticationContext,
                searchText: self.searchText,
                maxID: self.maxID,
                nextToken: nextToken,
                count: self.count,
                excludeReplies: self.excludeReplies,
                onlyMedia: self.onlyMedia,
                userIdentifier: self.userIdentifier
            )
        }
    }
    
    @available(*, deprecated, message: "")
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String?
        let offset: Int?
        let maxID: MastodonStatus.ID?
        let count: Int?
        let excludeReplies: Bool
        let excludeReblogs: Bool
        let onlyMedia: Bool
        let userIdentifier: MastodonUserIdentifier?
        let local: Bool?
        
        func map(maxID: MastodonStatus.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: self.authenticationContext,
                searchText: self.searchText,
                offset: self.offset,
                maxID: maxID,
                count: self.count,
                excludeReplies: self.excludeReplies,
                excludeReblogs: self.excludeReblogs,
                onlyMedia: self.onlyMedia,
                userIdentifier: self.userIdentifier,
                local: self.local
            )
        }
        
        func map(offset: Int?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: self.authenticationContext,
                searchText: self.searchText,
                offset: offset,
                maxID: self.maxID,
                count: self.count,
                excludeReplies: self.excludeReplies,
                excludeReblogs: self.excludeReblogs,
                onlyMedia: self.onlyMedia,
                userIdentifier: self.userIdentifier,
                local: self.local
            )
        }
    }
    
    @available(*, deprecated, message: "")
    struct Output {
        let result: Result
        
        let hasMore: Bool
        let nextInput: Input?
        
        enum Result {
            case twitter([Twitter.Entity.Tweet]) // v1
            case twitterV2([Twitter.Entity.V2.Tweet]) // v2
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
                let fetchContext = fetchContext.map(maxID: maxID)
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
                let fetchContext = fetchContext.map(maxID: maxID)
                return Input(fetchContext: .mastodon(fetchContext))
            }()
            return Output(
                result: .mastodon(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        }
    }
    
    static func publicTimeline(context: AppContext, input: Input) async throws -> Output {
        switch input.fetchContext {
        case .twitter(let fetchContext):
            assertionFailure("Invalid entry")
            throw AppError.implicit(.badRequest)
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await context.apiService.mastodonPublicTimeline(
                local: fetchContext.local ?? false,
                maxID: fetchContext.maxID,
                count: fetchContext.count ?? 100,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
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
                throw AppError.implicit(.badRequest)
            }
            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
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
                let fetchContext = fetchContext.map(maxID: maxID)

                return Input(fetchContext: .twitter(fetchContext))
            }()
            return Output(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let fetchContext):
            guard let accountID = fetchContext.userIdentifier?.id else {
                throw AppError.implicit(.badRequest)
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
                let fetchContext = fetchContext.map(maxID: maxID)
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
                throw AppError.implicit(.badRequest)
            }
            let authenticationContext = fetchContext.authenticationContext
            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
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
                let fetchContext = fetchContext.map(maxID: maxID)
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
                let fetchContext = fetchContext.map(maxID: maxID)
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

extension StatusListFetchViewModel {
    
    enum SearchInput {
        case twitter(SearchTwitterStatusFetchContext)
        case mastodon(SearchMastodonStatusFetchContext)
    }
    
    struct SearchOutput {
        let result: Result
        let nextInput: SearchInput?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }
    
    struct SearchTwitterStatusFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let searchText: String
        let onlyMedia: Bool
        let nextToken: String?
        let maxResults: Int?
        
        func map(nextToken: String) -> SearchTwitterStatusFetchContext {
            return SearchTwitterStatusFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                onlyMedia: onlyMedia,
                nextToken: nextToken,
                maxResults: maxResults
            )
        }
    }
    
    struct SearchMastodonStatusFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String
        let offset: Int
        let limit: Int?
        
        func map(offset: Int) -> SearchMastodonStatusFetchContext {
            return SearchMastodonStatusFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                limit: limit
            )
        }
    }
    
    static func searchTimeline(context: AppContext, input: SearchInput) async throws -> SearchOutput {
        switch input {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let queryText: String = try {
                let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty && searchText.count < 500 else {
                    throw AppError.implicit(.badRequest)
                }
                var query = searchText
                // default exclude retweet
                var options = ["-is:retweet"]
                if fetchContext.onlyMedia {
                    options.append("has:media")
                }
                // TODO: more options
                let suffix = options.joined(separator: " ")
                query += " (\(suffix))"
                return query
            }()
            
            let query = Twitter.API.V2.Search.RecentTweetQuery(
                query: queryText,
                maxResults: fetchContext.maxResults ?? 100,
                sinceID: nil,
                startTime: nil,
                nextToken: fetchContext.nextToken
            )
            let response = try await context.apiService.searchTwitterStatus(
                query: query,
                authenticationContext: authenticationContext
            )
            let content = response.value
            return SearchOutput(
                result: .twitterV2(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitter(fetchContext)
                }()
            )
            
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !searchText.isEmpty else {
                throw AppError.implicit(.badRequest)
            }
            let query = Mastodon.API.V2.Search.SearchQuery(
                type: .statuses,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                q: searchText,
                resolve: true,
                limit: fetchContext.limit,
                offset: fetchContext.offset,
                following: nil
            )
            let response = try await context.apiService.searchMastodon(
                query: query,
                authenticationContext: authenticationContext
            )
            return SearchOutput(
                result: .mastodon(response.value.statuses),
                nextInput: {
                    guard !response.value.statuses.isEmpty else { return nil }
                    let offset = fetchContext.offset + response.value.statuses.count
                    let fetchContext = fetchContext.map(offset: offset)
                    return .mastodon(fetchContext)
                }()
            )
        }
    }
    
}

extension StatusListFetchViewModel {

    enum HashtagInput {
        case twitter(SearchTwitterStatusFetchContext)
        case mastodon(HashtagMastodonStatusFetchContext)
    }
    
    struct HashtagOutput {
        let result: Result
        let nextInput: HashtagInput?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }
    
    
    struct HashtagMastodonStatusFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let hashtag: String
        let maxID: Mastodon.Entity.Status.ID?
        let limit: Int?
        
        func map(maxID: Mastodon.Entity.Status.ID) -> HashtagMastodonStatusFetchContext {
            return HashtagMastodonStatusFetchContext(
                authenticationContext: authenticationContext,
                hashtag: hashtag,
                maxID: maxID,
                limit: limit
            )
        }
    }
    
    static func hashtagTimeline(context: AppContext, input: HashtagInput) async throws -> HashtagOutput {
        switch input {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let queryText: String = try {
                let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty && searchText.count < 500 else {
                    throw AppError.implicit(.badRequest)
                }
                var query = searchText
                // default exclude retweet
                var options = ["-is:retweet"]
                if fetchContext.onlyMedia {
                    options.append("has:media")
                }
                // TODO: more options
                let suffix = options.joined(separator: " ")
                query += " (\(suffix))"
                return query
            }()
            
            let query = Twitter.API.V2.Search.RecentTweetQuery(
                query: queryText,
                maxResults: fetchContext.maxResults ?? 100,
                sinceID: nil,
                startTime: nil,
                nextToken: fetchContext.nextToken
            )
            let response = try await context.apiService.searchTwitterStatus(
                query: query,
                authenticationContext: authenticationContext
            )
            let content = response.value
            return HashtagOutput(
                result: .twitterV2(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitter(fetchContext)
                }()
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let query = Mastodon.API.Timeline.TimelineQuery(
                maxID: fetchContext.maxID,
                limit: fetchContext.limit
            )
            let response = try await context.apiService.mastodonHashtagTimeline(
                hashtag: fetchContext.hashtag,
                query: query,
                authenticationContext: authenticationContext
            )
            return HashtagOutput(
                result: .mastodon(response.value),
                nextInput: {
                    guard let maxID = response.value.last?.id else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return .mastodon(fetchContext)
                }()
            )
        }   // end switch input { }
    }
    

}
