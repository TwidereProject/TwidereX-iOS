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
        public let maxID: Twitter.Entity.V2.Tweet.ID?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        public let timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        
        public var needsAPIFallback: Bool = false
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            userID: Twitter.Entity.V2.User.ID,
            paginationToken: String?,
            maxID: Twitter.Entity.V2.Tweet.ID?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter,
            timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        ) {
            self.authenticationContext = authenticationContext
            self.userID = userID
            self.paginationToken = paginationToken
            self.maxID = maxID
            self.maxResults = maxResults
            self.filter = filter
            self.timelineKind = timelineKind
        }
        
        func map(paginationToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                userID: userID,
                paginationToken: paginationToken,
                maxID: maxID,
                maxResults: maxResults,
                filter: filter,
                timelineKind: timelineKind
            )
        }
        
        func map(maxID: Twitter.Entity.V2.Tweet.ID) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                userID: userID,
                paginationToken: paginationToken,
                maxID: maxID,
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
        
    enum TwitterResponse {
        case v2(Twitter.Response.Content<Twitter.API.V2.User.Timeline.TweetsContent>)
        case v1(Twitter.Response.Content<[Twitter.Entity.Tweet]>)
        
        func filter(fetchContext: TwitterFetchContext) -> StatusFetchViewModel.Result {
            switch self {
            case .v2(let response):
                let statuses = response.value.data ?? []
                let result = statuses.filter(fetchContext.filter.isIncluded)
                return .twitterV2(result)
            case .v1(let response):
                let result = response.value.filter(fetchContext.filter.isIncluded)
                return .twitter(result)
            }
        }
        
        func nextInput(fetchContext: TwitterFetchContext) -> Input? {
            switch self {
            case .v2(let response):
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            case .v1(let response):
                guard let maxID = response.value.last?.idStr else { return nil }
                guard maxID != fetchContext.maxID else { return nil }
                var fetchContext = fetchContext.map(maxID: maxID)
                fetchContext.needsAPIFallback = true
                return .twitter(fetchContext)
            }
        }
    }
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .twitter(let fetchContext):
            let response: TwitterResponse = try await {
                switch fetchContext.timelineKind {
                case .status, .media:
                    do {
                        guard !fetchContext.needsAPIFallback else {
                            throw Twitter.API.Error.ResponseError(httpResponseStatus: .ok, twitterAPIError: .rateLimitExceeded)
                        }
                        let response = try await api.twitterUserTimeline(
                            userID: fetchContext.userID,
                            query: .init(
                                sinceID: nil,
                                untilID: nil,
                                paginationToken: fetchContext.paginationToken,
                                maxResults: fetchContext.maxResults ?? 20
                            ),
                            authenticationContext: fetchContext.authenticationContext
                        )
                        return .v2(response)
                    } catch let error as Twitter.API.Error.ResponseError where error.twitterAPIError == .rateLimitExceeded {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Rate Limit] fallback to v1")
                        let response = try await api.twitterUserTimelineV1(
                            query: .init(
                                count: fetchContext.maxResults ?? 20,
                                userID: fetchContext.userID,
                                maxID: fetchContext.maxID,
                                sinceID: nil,
                                excludeReplies: false,
                                query: nil
                            ),
                            authenticationContext: fetchContext.authenticationContext
                        )
                        return .v1(response)
                    } catch {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                        throw error
                    }
                case .like:
                    do {
                        guard !fetchContext.needsAPIFallback else {
                            throw Twitter.API.Error.ResponseError(httpResponseStatus: .ok, twitterAPIError: .rateLimitExceeded)
                        }
                        let response = try await api.twitterLikeTimeline(
                            userID: fetchContext.userID,
                            query: .init(
                                sinceID: nil,
                                untilID: nil,
                                paginationToken: fetchContext.paginationToken,
                                maxResults: fetchContext.maxResults ?? 20
                            ),
                            authenticationContext: fetchContext.authenticationContext
                        )
                        return .v2(response)
                    } catch let error as Twitter.API.Error.ResponseError where error.twitterAPIError == .rateLimitExceeded {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Rate Limit] fallback to v1")
                        let response = try await api.twitterLikeTimelineV1(
                            query: .init(
                                count: fetchContext.maxResults ?? 20,
                                userID: fetchContext.userID,
                                maxID: fetchContext.maxID,
                                sinceID: nil,
                                excludeReplies: false,
                                query: nil
                            ),
                            authenticationContext: fetchContext.authenticationContext
                        )
                        return .v1(response)
                    } catch {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                        throw error
                    }
                }   // end switch
            }()
            // filter result
            let reulst = response.filter(fetchContext: fetchContext)
            let nextInput = response.nextInput(fetchContext: fetchContext)
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
