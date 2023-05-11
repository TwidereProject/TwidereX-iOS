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
        public let sinceID: Twitter.Entity.V2.Tweet.ID?
        public let untilID: Twitter.Entity.V2.Tweet.ID?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            sinceID: Twitter.Entity.V2.Tweet.ID?,
            untilID: Twitter.Entity.V2.Tweet.ID?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.sinceID = sinceID
            self.untilID = untilID
            self.maxResults = maxResults
            self.filter = filter
        }
        
        func map(untilID: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                sinceID: sinceID,
                untilID: untilID,
                maxResults: maxResults,
                filter: filter
            )
        }
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let sinceID: Mastodon.Entity.Status.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            sinceID: Mastodon.Entity.Status.ID?,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.sinceID = sinceID
            self.maxID = maxID
            self.count = count
            self.filter = filter
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                sinceID: sinceID,
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
            let responses = try await api.twitterHomeTimeline(
                query: .init(
                    sinceID: fetchContext.sinceID,
                    untilID: fetchContext.untilID,
                    paginationToken: nil,
                    maxResults: fetchContext.maxResults ?? 100,
                    onlyMedia: fetchContext.filter.rule.contains(.onlyMedia)
                ),
                authenticationContext: fetchContext.authenticationContext
            )
            let nextInput: Input? = {
                guard let last = responses.last,
                      last.value.meta.nextToken != nil,
                      let oldestID = last.value.meta.oldestID
                else { return nil }
                let fetchContext = fetchContext.map(untilID: oldestID)
                return .twitter(fetchContext)
            }()
            return .init(
                result: {
                    let statuses = responses
                        .map { $0.value.data }
                        .compactMap{ $0 }
                        .flatMap { $0 }
                    return .twitterV2(statuses)
                }(),
                backInput: nil,
                nextInput: nextInput.flatMap { .home($0) }
            )
        case .mastodon(let fetchContext):
            let authenticationContext = fetchContext.authenticationContext
            let responses = try await api.mastodonHomeTimeline(
                query: .init(
                    local: nil,
                    remote: nil,
                    onlyMedia: nil,
                    maxID: fetchContext.maxID,
                    sinceID: fetchContext.sinceID,
                    minID: nil,
                    limit: fetchContext.count ?? 100
                ),
                authenticationContext: authenticationContext
            )
            let nextInput: Input? = {
                guard let last = responses.last else { return nil }
                let noMore = last.value.isEmpty || (last.value.count == 1 && last.value[0].id == fetchContext.maxID)
                if noMore { return nil }
                guard let maxID = last.link?.maxID else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: {
                    let statuses = responses
                        .map { $0.value }
                        .compactMap{ $0 }
                        .flatMap { $0 }
                    return .mastodon(statuses)
                }(),
                backInput: nil,
                nextInput: nextInput.flatMap { .home($0) }
            )
        }   // end switch
    }   // end func
    
}
