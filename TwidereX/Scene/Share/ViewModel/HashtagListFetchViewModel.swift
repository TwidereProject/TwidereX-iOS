//
//  HashtagListFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import MastodonSDK

enum HashtagListFetchViewModel {
    
    static let logger = Logger(subsystem: "HashtagListFetchViewModel", category: "ViewModel")
    
    enum Result {
        case mastodon([Mastodon.Entity.Tag])
    }
}

extension HashtagListFetchViewModel {
    
    enum SearchInput {
        case mastodon(SearchMastodonHashtagFetchContext)
    }
    
    struct SearchOutput {
        let result: Result
        
        let hasMore: Bool
        let nextInput: SearchInput?
    }
    
    struct SearchMastodonHashtagFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let searchText: String
        let offset: Int
        let count: Int?
        
        func map(offset: Int) -> SearchMastodonHashtagFetchContext {
            return SearchMastodonHashtagFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count
            )
        }
    }
    
    static func search(context: AppContext, input: SearchInput) async throws -> SearchOutput {
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
            let nextInput: SearchInput? = {
                if noMore { return nil }
                let count = response.value.hashtags.count
                let fetchContext = fetchContext.map(offset: fetchContext.offset + count)
                return .mastodon(fetchContext)
            }()
            return SearchOutput(
                result: .mastodon(response.value.hashtags),
                hasMore: !noMore,
                nextInput: nextInput
            )
        }
    }
}
