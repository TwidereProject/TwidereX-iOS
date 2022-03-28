//
//  UserFetchViewModel+Search.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension UserFetchViewModel.Search {
    
    static let logger = Logger(subsystem: "UserFetchViewModel.Search", category: "ViewModel")
    
    public enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct Output {
        public let result: UserFetchViewModel.Result
        
        public let hasMore: Bool
        public let nextInput: Input?
    }
    
    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let searchText: String
        public let page: Int
        public let count: Int?
        
        public init(authenticationContext: TwitterAuthenticationContext, searchText: String, page: Int, count: Int?) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.page = page
            self.count = count
        }
        
        func map(page: Int) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                page: page,
                count: count
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let searchText: String
        public let following: Bool
        public let offset: Int
        public let count: Int?
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            searchText: String,
            following: Bool,
            offset: Int,
            count: Int?
        ) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.following = following
            self.offset = offset
            self.count = count
        }
        
        func map(offset: Int) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                following: following,
                offset: offset,
                count: count
            )
        }
    }

    public static func timeline(api: APIService, input: Input) async throws -> Output {
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
            let response = try await api.searchTwitterUser(
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            // here `query.count` limit to max 20 and only first 1000 users will returns
            let noMore = response.value.isEmpty || response.value.count < query.count
            let nextInput: Input? = {
                if noMore { return nil }
                let fetchContext = fetchContext.map(page: query.page + 1)
                return .twitter(fetchContext)
            }()
            return Output(
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
            // The v2 search API following filter not works. Use /v1/account/search as workaround
            // https://github.com/mastodon/mastodon/issues/17859
            if !fetchContext.following {
                let query = Mastodon.API.V2.Search.SearchQuery(
                    type: .accounts,
                    accountID: nil,
                    q: searchText,
                    limit: fetchContext.count ?? 20,
                    offset: fetchContext.offset
                )
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch at offset \(query.offset ?? -1)")
                let response = try await api.searchMastodon(
                    query: query,
                    authenticationContext: fetchContext.authenticationContext
                )
                let noMore = response.value.accounts.isEmpty
                let nextInput: Input? = {
                    if noMore { return nil }
                    let count = response.value.accounts.count
                    let fetchContext = fetchContext.map(offset: fetchContext.offset + count)
                    return .mastodon(fetchContext)
                }()
                return Output(
                    result: .mastodon(response.value.accounts),
                    hasMore: !noMore,
                    nextInput: nextInput
                )
            } else {
                let query = Mastodon.API.Account.SearchQuery(
                    q: searchText,
                    limit: fetchContext.count ?? 20,
                    resolve: true,
                    following: true
                )
                let response = try await api.searchMastodonUser(
                    query: query,
                    authenticationContext: fetchContext.authenticationContext
                )
                let content = response.value
                return Output(
                    result: .mastodon(content),
                    hasMore: false,     // is not a paging API
                    nextInput: nil
                )
            }
        }
    }
    
}
