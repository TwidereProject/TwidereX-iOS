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

public enum StatusFetchViewModel {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel", category: "ViewModel")
    
    public enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case twitterV2([Twitter.Entity.V2.Tweet]) // v2
        case mastodon([Mastodon.Entity.Status])
    }
    
}

extension StatusFetchViewModel {
    public enum Search { }
    public enum Hashtag { }
    public enum List { }
}

extension StatusFetchViewModel {
    @available(*, deprecated, message: "")
    public struct Input {
        public let fetchContext: FetchContext
        
        public init(fetchContext: StatusFetchViewModel.Input.FetchContext) {
            self.fetchContext = fetchContext
        }
        
        // TODO: refactor this with protocol and more specific case
        public enum FetchContext {
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
    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let searchText: String?
        public let maxID: TwitterStatus.ID?
        public let nextToken: String?
        public let count: Int?
        public let excludeReplies: Bool
        public let onlyMedia: Bool
        public let userIdentifier: TwitterUserIdentifier?
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            searchText: String?,
            maxID: TwitterStatus.ID?,
            nextToken: String?,
            count: Int?,
            excludeReplies: Bool,
            onlyMedia: Bool,
            userIdentifier: TwitterUserIdentifier?
        ) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.maxID = maxID
            self.nextToken = nextToken
            self.count = count
            self.excludeReplies = excludeReplies
            self.onlyMedia = onlyMedia
            self.userIdentifier = userIdentifier
        }
        
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
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let searchText: String?
        public let offset: Int?
        public let maxID: MastodonStatus.ID?
        public let count: Int?
        public let excludeReplies: Bool
        public let excludeReblogs: Bool
        public let onlyMedia: Bool
        public let userIdentifier: MastodonUserIdentifier?
        public let local: Bool?
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            searchText: String?,
            offset: Int?,
            maxID: MastodonStatus.ID?,
            count: Int?,
            excludeReplies: Bool,
            excludeReblogs: Bool,
            onlyMedia: Bool,
            userIdentifier: MastodonUserIdentifier?,
            local: Bool?
        ) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.offset = offset
            self.maxID = maxID
            self.count = count
            self.excludeReplies = excludeReplies
            self.excludeReblogs = excludeReblogs
            self.onlyMedia = onlyMedia
            self.userIdentifier = userIdentifier
            self.local = local
        }
        
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
    public struct Output {
        public let result: Result
        
        public let hasMore: Bool
        public let nextInput: Input?
        
        public enum Result {
            case twitter([Twitter.Entity.Tweet]) // v1
            case twitterV2([Twitter.Entity.V2.Tweet]) // v2
            case mastodon([Mastodon.Entity.Status])
        }
    }

}

extension StatusFetchViewModel {
    public static func homeTimeline(api: APIService, input: Input) async throws -> Output {
        switch input.fetchContext {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await api.twitterHomeTimeline(
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
            let response = try await api.mastodonHomeTimeline(
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
    
    public static func publicTimeline(api: APIService, input: Input) async throws -> Output {
        switch input.fetchContext {
        case .twitter(let fetchContext):
            assertionFailure("Invalid entry")
            throw AppError.implicit(.badRequest)
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await api.mastodonPublicTimeline(
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
    
    public static func userTimeline(api: APIService, input: Input) async throws -> Output {
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
            let response = try await api.twitterUserTimeline(
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
            let response = try await api.mastodonUserTimeline(
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
    
    public static func likeTimeline(api: APIService, input: Input) async throws -> Output {
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
            let response = try await api.twitterLikeTimeline(
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
            let response = try await api.mastodonLikeTimeline(
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
