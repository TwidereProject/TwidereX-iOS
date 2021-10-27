//
//  UserListFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwitterSDK

enum UserListFetchViewModel {
    enum Result {
        case twitter([Twitter.Entity.User]) // v1
        case twitterV2([Twitter.Entity.V2.User]) // v2
        // case mastodon([Mastodon.Entity.Status])
    }
}

extension UserListFetchViewModel {
    enum SearchInput {
        case twitter(SearchTwitterUserFetchContext)
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
                authenticationContext: self.authenticationContext,
                searchText: self.searchText,
                page: page,
                count: self.count
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
                count: fetchContext.count ?? 100
            )
            let response = try await context.apiService.searchTwitterUser(
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            // here `query.count` limit to max 1000
            let noMore = response.value.isEmpty // only mark empty when no results returns
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
        }
    }
}
