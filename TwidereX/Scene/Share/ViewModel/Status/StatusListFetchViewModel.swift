//
//  StatusFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK
import TwidereCore

enum StatusFetchViewModel {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel", category: "ViewModel")
    
    enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case twitterV2([Twitter.Entity.V2.Tweet]) // v2
        case mastodon([Mastodon.Entity.Status])
    }
    
}

extension StatusFetchViewModel {
    enum Search { }
    enum Hashtag { }
    enum List { }
}

extension StatusFetchViewModel {
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

extension StatusFetchViewModel {
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
            let _maxID = response.link?.maxID
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID) || _maxID == nil || _maxID == fetchContext.maxID
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = _maxID else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return Input(fetchContext: .mastodon(fetchContext))
            }()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): hasMore: \(!noMore)")
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
