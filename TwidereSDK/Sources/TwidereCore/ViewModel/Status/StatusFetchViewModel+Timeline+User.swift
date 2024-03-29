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
import CoreData
import CoreDataStack

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
        public let protected: Bool
        public let paginationToken: String?
        public let maxID: Twitter.Entity.V2.Tweet.ID?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        public let timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        
        public var needsAPIFallback: Bool = false
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            userID: Twitter.Entity.V2.User.ID,
            protected: Bool,
            paginationToken: String?,
            maxID: Twitter.Entity.V2.Tweet.ID?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter,
            timelineKind: StatusFetchViewModel.Timeline.Kind.UserTimelineContext.TimelineKind
        ) {
            self.authenticationContext = authenticationContext
            self.userID = userID
            self.protected = protected
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
                protected: protected,
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
                protected: protected,
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
        case local([TwitterStatus.ID])
        
        func filter(fetchContext: TwitterFetchContext) -> StatusFetchViewModel.Result {
            switch self {
            case .v2(let response):
                let statuses = response.value.data ?? []
                let result = statuses.filter(fetchContext.filter.isIncluded)
                return .twitterV2(result)
            case .v1(let response):
                let result = response.value.filter(fetchContext.filter.isIncluded)
                return .twitter(result)
            case .local(let statusIDs):
                return .twitterIDs(statusIDs)
            }
        }
        
        func nextInput(fetchContext: TwitterFetchContext) -> Input? {
            switch self {
            case .v2(let response):
                guard response.value.meta.resultCount > 0 else { return nil }
                guard let nextToken = response.value.meta.nextToken else { return nil }
                guard nextToken != fetchContext.paginationToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            case .v1(let response):
                guard let maxID = response.value.last?.idStr else { return nil }
                guard maxID != fetchContext.maxID else { return nil }
                var fetchContext = fetchContext.map(maxID: maxID)
                fetchContext.needsAPIFallback = true
                return .twitter(fetchContext)
            case .local:
                return nil
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
                        guard !fetchContext.protected else {
                            throw EmptyState.unableToAccess()
                        }
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [UserTimeline] fetch user timeline: userID[\(fetchContext.userID)] cursor[\(fetchContext.paginationToken ?? "<nil>")]")
                        let response = try await api.twitterUserTimeline(
                            userID: fetchContext.userID,
                            query: .init(
                                sinceID: nil,
                                untilID: nil,
                                paginationToken: fetchContext.paginationToken,
                                maxResults: fetchContext.maxResults ?? 20,
                                onlyMedia: fetchContext.filter.rule.contains(.onlyMedia)
                            ),
                            authenticationContext: fetchContext.authenticationContext
                        )
                        return .v2(response)
                    } catch {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [UserTimeline] fetch failure: \(error.localizedDescription)")
                        throw error
                    }
                case .like:
                    do {
                        if fetchContext.paginationToken != nil {
                            throw AppError.implicit(.badRequest)
                        }
                        
                        let managedObjectContext = api.coreDataStack.persistentContainer.viewContext
                        let statusIDs: [TwitterStatus.ID] = try await managedObjectContext.perform {
                            let userRequest = TwitterUser.sortedFetchRequest
                            userRequest.predicate = TwitterUser.predicate(id: fetchContext.userID)
                            guard let user = try managedObjectContext.fetch(userRequest).first else {
                                throw AppError.implicit(.badRequest)
                            }
                            let statusIDs = user.like.map { $0.id }
                            let statusRequest = TwitterStatus.sortedFetchRequest
                            statusRequest.predicate = TwitterStatus.predicate(ids: statusIDs)
                            let results = try managedObjectContext.fetch(statusRequest)
                            return results.map { $0.id }
                        }
                        return .local(statusIDs)
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
