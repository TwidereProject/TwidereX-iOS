//
//  UserFetchViewModel+Friendship.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension UserFetchViewModel.Friendship {
    
    static let logger = Logger(subsystem: "UserFetchViewModel.Friendship", category: "ViewModel")
    
    public enum Kind {
        case following
        case follower
    }
    
    public enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct Output {
        public let result: UserFetchViewModel.Result
        public let hasMore: Bool
        public let nextInput: Input?
        public let kind: Kind
    }
    
    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let kind: Kind
        public let userID: Twitter.Entity.V2.User.ID
        public let paginationToken: String?
        public let maxResults: Int?
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            kind: UserFetchViewModel.Friendship.Kind,
            userID: Twitter.Entity.V2.User.ID,
            paginationToken: String?,
            maxResults: Int?
        ) {
            self.authenticationContext = authenticationContext
            self.kind = kind
            self.userID = userID
            self.paginationToken = paginationToken
            self.maxResults = maxResults
        }
        
        func map(paginationToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                kind: kind,
                userID: userID,
                paginationToken: paginationToken,
                maxResults: maxResults
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let kind: Kind
        public let userID: Mastodon.Entity.Account.ID
        public let maxID: Mastodon.Entity.Account.ID?
        public let limit: Int?
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            kind: UserFetchViewModel.Friendship.Kind,
            userID: Mastodon.Entity.Account.ID,
            maxID: Mastodon.Entity.Account.ID?,
            limit: Int?
        ) {
            self.authenticationContext = authenticationContext
            self.kind = kind
            self.userID = userID
            self.maxID = maxID
            self.limit = limit
        }
        
        func map(maxID: Mastodon.Entity.Account.ID) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                kind: kind,
                userID: userID,
                maxID: maxID,
                limit: limit
            )
        }
    }

    public static func list(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let query = Twitter.API.V2.User.Follow.FriendshipListQuery(
                userID: fetchContext.userID,
                maxResults: fetchContext.maxResults ?? (fetchContext.paginationToken == nil ? 20 : 200),
                paginationToken: fetchContext.paginationToken
            )
            let response = try await { () -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> in
                switch fetchContext.kind {
                case .following:
                    return try await api.twitterUserFollowingList(query: query, authenticationContext: fetchContext.authenticationContext)
                case .follower:
                    return try await api.twitterUserFollowerList(query: query, authenticationContext: fetchContext.authenticationContext)
                }
            }()
            let count = response.value.data?.count ?? 0
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(count) users")
            let noMore = response.value.meta.nextToken == nil
            let nextInput: Input? = {
                if noMore { return nil }
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            }()
            return Output(
                result: .twitterV2(response.value.data ?? []),
                hasMore: !noMore,
                nextInput: nextInput,
                kind: fetchContext.kind
            )
        case .mastodon(let fetchContext):
            let response = try await { () -> Mastodon.Response.Content<[Mastodon.Entity.Account]> in
                let limit = fetchContext.limit ?? (fetchContext.maxID == nil ? 20 : 40)
                switch fetchContext.kind {
                case .following:
                    let query = Mastodon.API.Account.FollowingQuery(maxID: fetchContext.maxID, limit: limit)
                    return try await api.mastodonUserFollowingList(userID: fetchContext.userID, query: query, authenticationContext: fetchContext.authenticationContext)
                case .follower:
                    let query = Mastodon.API.Account.FollowerQuery(maxID: fetchContext.maxID, limit: limit)
                    return try await api.mastodonUserFollowerList(userID: fetchContext.userID, query: query, authenticationContext: fetchContext.authenticationContext)
                }
            }()
            let count = response.value.count
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(count) users")
            let noMore: Bool = {
                guard let last = response.value.last else { return true }
                return last.id != fetchContext.userID
            }()
            let nextInput: Input? = {
                if noMore { return nil }
                guard let last = response.value.last else { return nil }
                let fetchContext = fetchContext.map(maxID: last.id)
                return .mastodon(fetchContext)
            }()
            return Output(
                result: .mastodon(response.value),
                hasMore: !noMore,
                nextInput: nextInput,
                kind: fetchContext.kind
            )
        }
    }
    
}
