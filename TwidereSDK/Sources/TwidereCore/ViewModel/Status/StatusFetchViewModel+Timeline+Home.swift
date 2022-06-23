//
//  StatusFetchViewModel+Timeline+Home.swift
//  
//
//  Created by MainasuK on 2022-6-7.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum Home { }
}

extension StatusFetchViewModel.Timeline.Home {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.Home", category: "ViewModel")
    
    public enum Input: Hashable {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct TwitterFetchContext: Hashable {
        public let authenticationContext: TwitterAuthenticationContext
        public let untilID: Twitter.Entity.V2.Tweet.ID?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            untilID: Twitter.Entity.V2.Tweet.ID?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.untilID = untilID
            self.maxResults = maxResults
            self.filter = filter
        }
        
        func map(untilID: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                untilID: untilID,
                maxResults: maxResults,
                filter: filter
            )
        }
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.maxID = maxID
            self.count = count
            self.filter = filter
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                maxID: maxID,
                count: count,
                filter: filter
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.Home {
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .twitter(let fetchContext):
            let response = try await api.twitterHomeTimeline(
                query: .init(
                    untilID: fetchContext.untilID,
                    paginationToken: nil,
                    maxResults: fetchContext.maxResults ?? 100
                ),
                authenticationContext: fetchContext.authenticationContext
            )
            let nextInput: Input? = {
                guard response.value.meta.nextToken != nil,
                      let oldestID = response.value.meta.oldestID
                else { return nil }
                let fetchContext = fetchContext.map(untilID: oldestID)
                return .twitter(fetchContext)
            }()
            return .init(
                result: .twitterV2(response.value.data ?? []),
                backInput: nil,
                nextInput: nextInput.flatMap { .home($0) }
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let response = try await api.mastodonHomeTimeline(
                maxID: fetchContext.maxID,
                count: fetchContext.count ?? 50,
                authenticationContext: authenticationContext
            )
            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
            let nextInput: Input? = {
                if noMore { return nil }
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: .mastodon(response.value),
                backInput: nil,
                nextInput: nextInput.flatMap { .home($0) }
            )
        }
    }
    
}
