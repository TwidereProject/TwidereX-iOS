//
//  StatusFetchViewModel+Search.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Search {
    
    public enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct Output {
        public let result: StatusFetchViewModel.Result
        public let nextInput: Input?
        
        public var hasMore: Bool {
            nextInput != nil
        }
    }
    
    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let searchText: String
        public let onlyMedia: Bool
        public let nextToken: String?
        public let maxResults: Int?
        
        public init(authenticationContext: TwitterAuthenticationContext, searchText: String, onlyMedia: Bool, nextToken: String?, maxResults: Int?) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.onlyMedia = onlyMedia
            self.nextToken = nextToken
            self.maxResults = maxResults
        }
        
        func map(nextToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                onlyMedia: onlyMedia,
                nextToken: nextToken,
                maxResults: maxResults
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let searchText: String
        public let offset: Int
        public let limit: Int?
        
        public init(authenticationContext: MastodonAuthenticationContext, searchText: String, offset: Int, limit: Int?) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.offset = offset
            self.limit = limit
        }
        
        func map(offset: Int) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                limit: limit
            )
        }
    }
    
    public static func timeline(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let queryText: String = try {
                let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty && searchText.count < 500 else {
                    throw AppError.implicit(.badRequest)
                }
                var query = searchText
                // default exclude retweet
                var options = ["-is:retweet"]
                if fetchContext.onlyMedia {
                    options.append("has:media")
                }
                // TODO: more options
                let suffix = options.joined(separator: " ")
                query += " (\(suffix))"
                return query
            }()
            
            let query = Twitter.API.V2.Search.RecentTweetQuery(
                query: queryText,
                maxResults: fetchContext.maxResults ?? 100,
                sinceID: nil,
                startTime: nil,
                nextToken: fetchContext.nextToken
            )
            let response = try await api.searchTwitterStatus(
                query: query,
                authenticationContext: authenticationContext
            )
            let content = response.value
            return Output(
                result: .twitterV2(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitter(fetchContext)
                }()
            )
            
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !searchText.isEmpty else {
                throw AppError.implicit(.badRequest)
            }
            let query = Mastodon.API.V2.Search.SearchQuery(
                type: .statuses,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                q: searchText,
                resolve: true,
                limit: fetchContext.limit,
                offset: fetchContext.offset,
                following: nil
            )
            let response = try await api.searchMastodon(
                query: query,
                authenticationContext: authenticationContext
            )
            return Output(
                result: .mastodon(response.value.statuses),
                nextInput: {
                    guard !response.value.statuses.isEmpty else { return nil }
                    let offset = fetchContext.offset + response.value.statuses.count
                    let fetchContext = fetchContext.map(offset: offset)
                    return .mastodon(fetchContext)
                }()
            )
        }
    }
    
}
