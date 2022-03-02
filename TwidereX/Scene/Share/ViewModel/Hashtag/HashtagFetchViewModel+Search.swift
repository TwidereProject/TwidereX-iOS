//
//  HashtagFetchViewModel+Search.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import MastodonSDK

extension HashtagFetchViewModel.Search {
    
    static let logger = Logger(subsystem: "HashtagFetchViewModel.Search", category: "ViewModel")
    
    enum Input {
        case mastodon(MastodonFetchContext)
    }
    
    struct Output {
        let result: HashtagFetchViewModel.Result
        
        let hasMore: Bool
        let nextInput: Input?
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
    
    static func list(context: AppContext, input: Input) async throws -> Output {
        switch input {
        case .mastodon(let fetchContext):
            let searchText: String = try {
                let searchText = fetchContext.searchText
                guard !searchText.isEmpty, searchText.count < 512 else {
                    throw AppError.implicit(.badRequest)
                }
                return searchText
            }()
            let query = Mastodon.API.V2.Search.SearchQuery(
                type: .hashtags,
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
            let noMore = response.value.hashtags.isEmpty
            let nextInput: Input? = {
                if noMore { return nil }
                let count = response.value.hashtags.count
                let fetchContext = fetchContext.map(offset: fetchContext.offset + count)
                return .mastodon(fetchContext)
            }()
            return Output(
                result: .mastodon(response.value.hashtags),
                hasMore: !noMore,
                nextInput: nextInput
            )
        }
    }
    
}
