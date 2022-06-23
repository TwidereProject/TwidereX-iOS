//
//  StatusFetchViewModel+Timeline+User.swift
//  
//
//  Created by MainasuK on 2022-6-13.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum User { }
}

extension StatusFetchViewModel.Timeline.User {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.User", category: "ViewModel")
    
    public enum Input: Hashable {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct TwitterFetchContext: Hashable {
        public let authenticationContext: TwitterAuthenticationContext
        public let userID: Twitter.Entity.V2.User.ID
        public let paginationToken: String?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        public let timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            userID: Twitter.Entity.V2.User.ID,
            paginationToken: String?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter,
            timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        ) {
            self.authenticationContext = authenticationContext
            self.userID = userID
            self.paginationToken = paginationToken
            self.maxResults = maxResults
            self.filter = filter
            self.timelineKind = timelineKind
        }
        
        func map(paginationToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                userID: userID,
                paginationToken: paginationToken,
                maxResults: maxResults,
                filter: filter,
                timelineKind: timelineKind
            )
        }
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let accountID: Mastodon.Entity.Account.ID
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        public let timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            accountID: Mastodon.Entity.Account.ID,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter,
            timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        ) {
            self.authenticationContext = authenticationContext
            self.accountID = accountID
            self.maxID = maxID
            self.count = count
            self.filter = filter
            self.timelineKind = timelineKind
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                accountID: accountID,
                maxID: maxID,
                count: count,
                filter: filter,
                timelineKind: timelineKind
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.User {
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .twitter(let fetchContext):
            let response: Twitter.Response.Content<Twitter.API.V2.User.Timeline.TweetsContent> = try await {
                switch fetchContext.timelineKind {
                case .status, .media:
                    return try await api.twitterUserTimeline(
                        userID: fetchContext.userID,
                        query: .init(
                            sinceID: nil,
                            untilID: nil,
                            paginationToken: fetchContext.paginationToken,
                            maxResults: fetchContext.maxResults ?? 20
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                case .like:
                    return try await api.twitterLikeTimeline(
                        userID: fetchContext.userID,
                        query: .init(
                            sinceID: nil,
                            untilID: nil,
                            paginationToken: fetchContext.paginationToken,
                            maxResults: fetchContext.maxResults ?? 20
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                }
            }()
            // filter result
            let reulst: StatusFetchViewModel.Result = {
                let statuses = response.value.data ?? []
                let result = statuses.filter(fetchContext.filter.isIncluded)
                return .twitterV2(result)
            }()
            let nextInput: Input? = {
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            }()
            return .init(
                result: reulst,
                backInput: nil,
                nextInput: nextInput.flatMap { .user($0) }
            )
        case .mastodon(let fetchContext):
            let response: Mastodon.Response.Content<[Mastodon.Entity.Status]> = try await {
                switch fetchContext.timelineKind {
                case .status, .media:
                    return try await api.mastodonUserTimeline(
                        accountID: fetchContext.accountID,
                        query: .init(
                            maxID: fetchContext.maxID,
                            sinceID: nil,
                            excludeReplies: nil,
                            excludeReblogs: nil,
                            onlyMedia: fetchContext.filter.rule.contains(.onlyMedia),
                            limit: fetchContext.count ?? 20
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                case .like:
                    return try await api.mastodonLikeTimeline(
                        query: .init(
                            limit: fetchContext.count ?? 20,
                            minID: nil,
                            maxID: fetchContext.maxID,
                            sinceID: nil
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                }
            }()
            let nextInput: Input? = {
                guard let maxID = response.link?.maxID else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: .mastodon(response.value),
                backInput: nil,
                nextInput: nextInput.flatMap { .user($0) }
            )
        }   // end switch
    }
    
}
