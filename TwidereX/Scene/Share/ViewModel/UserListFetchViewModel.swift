//
//  UserListFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwidereCore
import TwitterSDK
import MastodonSDK

enum UserListFetchViewModel {
    
    static let logger = Logger(subsystem: "UserListFetchViewModel", category: "ViewModel")
    
    enum Result {
        case twitter([Twitter.Entity.User]) // v1
        case twitterV2([Twitter.Entity.V2.User]) // v2
        case mastodon([Mastodon.Entity.Account])
    }
}

extension UserListFetchViewModel {
    
    enum SearchInput {
        case twitter(SearchTwitterUserFetchContext)
        case mastodon(SearchMastodonUserFetchContext)
    }
    
    struct SearchOutput {
        let result: Result
        
        let hasMore: Bool
        let nextInput: SearchInput?
    }
    
    struct SearchTwitterUserFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let searchText: String
        let page: Int
        let count: Int?
        
        func map(page: Int) -> SearchTwitterUserFetchContext {
            return SearchTwitterUserFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                page: page,
                count: count
            )
        }
    }
    
    struct SearchMastodonUserFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String
        let offset: Int
        let count: Int?
        
        func map(offset: Int) -> SearchMastodonUserFetchContext {
            return SearchMastodonUserFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count
            )
        }
    }

    static func search(context: AppContext, input: SearchInput) async throws -> SearchOutput {
        switch input {
        case .twitter(let fetchContext):
            let searchText: String = try {
                let searchText = fetchContext.searchText
                guard !searchText.isEmpty, searchText.count < 512 else {
                    throw AppError.implicit(.badRequest)
                }
                return searchText
            }()
            let query = Twitter.API.Users.SearchQuery(
                q: searchText,
                page: fetchContext.page,
                count: fetchContext.count ?? 20
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch at page \(query.page)")
            let response = try await context.apiService.searchTwitterUser(
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            // here `query.count` limit to max 20 and only first 1000 users will returns
            let noMore = response.value.isEmpty || response.value.count < query.count
            let nextInput: SearchInput? = {
                if noMore { return nil }
                let fetchContext = fetchContext.map(page: query.page + 1)
                return .twitter(fetchContext)
            }()
            return SearchOutput(
                result: .twitter(response.value),
                hasMore: !noMore,
                nextInput: nextInput
            )
        case .mastodon(let fetchContext):
            let searchText: String = try {
                let searchText = fetchContext.searchText
                guard !searchText.isEmpty, searchText.count < 512 else {
                    throw AppError.implicit(.badRequest)
                }
                return searchText
            }()
            let query = Mastodon.API.V2.Search.SearchQuery(
                type: .accounts,
                accountID: nil,
                q: searchText,
                limit: fetchContext.count ?? 20,
                offset: fetchContext.offset
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch at offset \(query.offset ?? -1)")
            let response = try await context.apiService.searchMastodon(
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let noMore = response.value.accounts.isEmpty
            let nextInput: SearchInput? = {
                if noMore { return nil }
                let count = response.value.accounts.count
                let fetchContext = fetchContext.map(offset: fetchContext.offset + count)
                return .mastodon(fetchContext)
            }()
            return SearchOutput(
                result: .mastodon(response.value.accounts),
                hasMore: !noMore,
                nextInput: nextInput
            )
        }
    }
    
}

extension UserListFetchViewModel {
    
    enum FriendshipListKind {
        case following
        case follower
    }
    
    enum FriendshipListInput {
        case twitter(FriendshipListTwitterUserFetchContext)
        case mastodon(FriendshipListMastodonUserFetchContext)
    }
    
    struct FriendshipListOutput {
        let result: Result
        let hasMore: Bool
        let nextInput: FriendshipListInput?
        let kind: FriendshipListKind
    }
    
    struct FriendshipListTwitterUserFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let kind: FriendshipListKind
        let userID: Twitter.Entity.V2.User.ID
        let paginationToken: String?
        let maxResults: Int?
        
        func map(paginationToken: String) -> FriendshipListTwitterUserFetchContext {
            return FriendshipListTwitterUserFetchContext(
                authenticationContext: authenticationContext,
                kind: kind,
                userID: userID,
                paginationToken: paginationToken,
                maxResults: maxResults
            )
        }
    }
    
    struct FriendshipListMastodonUserFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String
        let offset: Int
        let count: Int?
        
        func map(offset: Int) -> SearchMastodonUserFetchContext {
            return SearchMastodonUserFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count
            )
        }
    }

    static func friendshipList(context: AppContext, input: FriendshipListInput) async throws -> FriendshipListOutput {
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
            let nextInput: FriendshipListInput? = {
                if noMore { return nil }
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            }()
            return FriendshipListOutput(
                result: .twitterV2(response.value.data ?? []),
                hasMore: !noMore,
                nextInput: nextInput,
                kind: fetchContext.kind
            )
        case .mastodon(let fetchContext):
            fatalError()
//            let searchText: String = try {
//                let searchText = fetchContext.searchText
//                guard !searchText.isEmpty, searchText.count < 512 else {
//                    throw AppError.implicit(.badRequest)
//                }
//                return searchText
//            }()
//            let query = Mastodon.API.V2.Search.SearchQuery(
//                type: .accounts,
//                accountID: nil,
//                q: searchText,
//                limit: fetchContext.count ?? 20,
//                offset: fetchContext.offset
//            )
//            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch at offset \(query.offset ?? -1)")
//            let response = try await context.apiService.searchMastodon(
//                query: query,
//                authenticationContext: fetchContext.authenticationContext
//            )
//            let noMore = response.value.accounts.isEmpty
//            let nextInput: SearchInput? = {
//                if noMore { return nil }
//                let count = response.value.accounts.count
//                let fetchContext = fetchContext.map(offset: fetchContext.offset + count)
//                return .mastodon(fetchContext)
//            }()
//            return SearchOutput(
//                result: .mastodon(response.value.accounts),
//                hasMore: !noMore,
//                nextInput: nextInput
//            )
        }
    }
    
}
