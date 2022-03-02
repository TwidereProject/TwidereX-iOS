//
//  UserFetchViewModel+Friendship.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwidereCore
import TwitterSDK
import MastodonSDK

extension UserFetchViewModel.Friendship {
    
    static let logger = Logger(subsystem: "UserFetchViewModel.Friendship", category: "ViewModel")
    
    enum Kind {
        case following
        case follower
    }
    
    enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    struct Output {
        let result: UserFetchViewModel.Result
        let hasMore: Bool
        let nextInput: Input?
        let kind: Kind
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let kind: Kind
        let userID: Twitter.Entity.V2.User.ID
        let paginationToken: String?
        let maxResults: Int?
        
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
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let kind: Kind
        let userID: Mastodon.Entity.Account.ID
        let maxID: Mastodon.Entity.Account.ID?
        let limit: Int?
        
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

    static func list(context: AppContext, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let query = Twitter.API.V2.User.Follow.FriendshipListQuery(
                userID: fetchContext.userID,
                maxResults: fetchContext.maxResults ?? (fetchContext.paginationToken == nil ? 200 : 1000),
                paginationToken: fetchContext.paginationToken
            )
            let response = try await { () -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> in
                switch fetchContext.kind {
                case .following:
                    return try await context.apiService.twitterUserFollowingList(query: query, authenticationContext: fetchContext.authenticationContext)
                case .follower:
                    return try await context.apiService.twitterUserFollowerList(query: query, authenticationContext: fetchContext.authenticationContext)
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
                    return try await context.apiService.mastodonUserFollowingList(userID: fetchContext.userID, query: query, authenticationContext: fetchContext.authenticationContext)
                case .follower:
                    let query = Mastodon.API.Account.FollowerQuery(maxID: fetchContext.maxID, limit: limit)
                    return try await context.apiService.mastodonUserFollowerList(userID: fetchContext.userID, query: query, authenticationContext: fetchContext.authenticationContext)
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
