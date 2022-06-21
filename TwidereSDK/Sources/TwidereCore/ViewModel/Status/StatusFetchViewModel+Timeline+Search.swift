//
//  StatusFetchViewModel+Timeline+Search.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum Search { }
}

extension StatusFetchViewModel.Timeline.Search {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.Search", category: "ViewModel")
    
    public enum Input: Hashable {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct TwitterFetchContext: Hashable {
        public let authenticationContext: TwitterAuthenticationContext
        public let searchText: String
        public let untilID: Twitter.Entity.V2.Tweet.ID?
        public let nextToken: String?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            searchText: String,
            untilID: Twitter.Entity.V2.Tweet.ID?,
            nextToken: String?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.untilID = untilID
            self.nextToken = nextToken
            self.maxResults = maxResults
            self.filter = filter
        }
        
        func map(untilID: Twitter.Entity.V2.Tweet.ID?, nextToken: String?) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                untilID: untilID,
                nextToken: nextToken,
                maxResults: maxResults,
                filter: filter
            )
        }
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let searchText: String
        public let offset: Int
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            searchText: String,
            offset: Int,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.offset = offset
            self.count = count
            self.filter = filter
        }
        
        func map(offset: Int) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count,
                filter: filter
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.Search {
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .twitter(let fetchContext):
            let queryText: String = try {
                let searchText = fetchContext.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty && searchText.count < 500 else {
                    throw AppError.implicit(.badRequest)
                }
                var query = searchText
                // default exclude retweet
                var options = ["-is:retweet"]
                if fetchContext.filter.rule.contains(.onlyMedia) {
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
                authenticationContext: fetchContext.authenticationContext
            )
            let nextInput: Input? = {
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(untilID: response.value.meta.oldestID, nextToken: nextToken)
                return .twitter(fetchContext)
            }()
            return .init(
                result: .twitterV2(response.value.data ?? []),
                backInput: nil,
                nextInput: nextInput.flatMap { .search($0) }
            )
        case .mastodon(let fetchContext):
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
                limit: fetchContext.count,
                offset: fetchContext.offset,
                following: nil
            )
            let response = try await api.searchMastodon(
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let nextInput: Input? = {
                guard !response.value.statuses.isEmpty else { return nil }
                let offset = fetchContext.offset + response.value.statuses.count
                let fetchContext = fetchContext.map(offset: offset)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: .mastodon(response.value.statuses),
                backInput: nil,
                nextInput: nextInput.flatMap { .search($0) }
            )
        }   // end switch
    }
    
}
