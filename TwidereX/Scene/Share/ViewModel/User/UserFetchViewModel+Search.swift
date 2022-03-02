//
//  UserFetchViewModel+Search.swift
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

extension UserFetchViewModel.Search {
    
    static let logger = Logger(subsystem: "UserFetchViewModel.Search", category: "ViewModel")
    
    enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    struct Output {
        let result: UserFetchViewModel.Result
        
        let hasMore: Bool
        let nextInput: Input?
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let searchText: String
        let page: Int
        let count: Int?
        
        func map(page: Int) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                page: page,
                count: count
            )
        }
    }
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String
        let offset: Int
        let count: Int?
        
        func map(offset: Int) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count
            )
        }
    }

    static func timeline(context: AppContext, input: Input) async throws -> Output {
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
        }
    }
    
}
