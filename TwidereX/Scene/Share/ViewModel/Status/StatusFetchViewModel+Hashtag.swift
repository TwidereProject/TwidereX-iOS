//
//  StatusFetchViewModel+Hashtag.swift
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
import TwidereCore

extension StatusFetchViewModel.Hashtag {

    enum Input {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    struct Output {
        let result: StatusFetchViewModel.Result
        let nextInput: Input?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }
    
    typealias TwitterFetchContext = StatusFetchViewModel.Search.TwitterFetchContext
    
    struct MastodonFetchContext {
        let authenticationContext: MastodonAuthenticationContext
        let hashtag: String
        let maxID: Mastodon.Entity.Status.ID?
        let limit: Int?
        
        func map(maxID: Mastodon.Entity.Status.ID) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                hashtag: hashtag,
                maxID: maxID,
                limit: limit
            )
        }
    }
    
    static func timeline(context: AppContext, input: Input) async throws -> Output {
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
            let response = try await context.apiService.searchTwitterStatus(
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
            let query = Mastodon.API.Timeline.TimelineQuery(
                maxID: fetchContext.maxID,
                limit: fetchContext.limit
            )
            let response = try await context.apiService.mastodonHashtagTimeline(
                hashtag: fetchContext.hashtag,
                query: query,
                authenticationContext: authenticationContext
            )
            return Output(
                result: .mastodon(response.value),
                nextInput: {
                    guard let maxID = response.value.last?.id else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return .mastodon(fetchContext)
                }()
            )
        }   // end switch input { }
    }
    

}
