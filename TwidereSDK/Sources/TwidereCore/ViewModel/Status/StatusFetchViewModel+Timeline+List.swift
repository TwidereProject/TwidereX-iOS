//
//  StatusFetchViewModel+Timeline+List.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum List { }
}

extension StatusFetchViewModel.Timeline.List {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.List", category: "ViewModel")
    
    public enum Input: Hashable {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct TwitterFetchContext: Hashable {
        public let managedObjectContext: NSManagedObjectContext
        public let authenticationContext: TwitterAuthenticationContext
        public let list: ManagedObjectRecord<TwitterList>
        public let paginationToken: String?
        public let maxID: Twitter.Entity.Tweet.ID?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public var needsAPIFallback = false
        
        public init(
            managedObjectContext: NSManagedObjectContext,
            authenticationContext: TwitterAuthenticationContext,
            list: ManagedObjectRecord<TwitterList>,
            paginationToken: String?,
            maxID: Twitter.Entity.Tweet.ID?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.managedObjectContext = managedObjectContext
            self.authenticationContext = authenticationContext
            self.list = list
            self.paginationToken = paginationToken
            self.maxID = maxID
            self.maxResults = maxResults
            self.filter = filter
        }
        
        func map(paginationToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                managedObjectContext: managedObjectContext,
                authenticationContext: authenticationContext,
                list: list,
                paginationToken: paginationToken,
                maxID: maxID,
                maxResults: maxResults,
                filter: filter
            )
        }
        
        func map(maxID: Twitter.Entity.Tweet.ID) -> TwitterFetchContext {
            return TwitterFetchContext(
                managedObjectContext: managedObjectContext,
                authenticationContext: authenticationContext,
                list: list,
                paginationToken: paginationToken,
                maxID: maxID,
                maxResults: maxResults,
                filter: filter
            )
        }
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let list: ManagedObjectRecord<MastodonList>
        public let minID: Mastodon.Entity.Status.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            list: ManagedObjectRecord<MastodonList>,
            minID: Mastodon.Entity.Status.ID?,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.list = list
            self.minID = minID
            self.maxID = maxID
            self.count = count
            self.filter = filter
        }
        
        func map(minID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                minID: minID,
                maxID: nil,
                count: count,
                filter: filter
            )
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                minID: nil,
                maxID: maxID,
                count: count,
                filter: filter
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.List {
    
    enum TwitterResponse {
        case v2(Twitter.Response.Content<Twitter.Entity.V2.TimelineContent>)
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
        
        func backInput(fetchContext: TwitterFetchContext) -> Input? {
            switch self {
            case .v2(let response):
                guard let previousToken = response.value.meta.previousToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: previousToken)
                return .twitter(fetchContext)
            case .v1:
                return nil
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
                do {
                    guard !fetchContext.needsAPIFallback else {
                        throw Twitter.API.Error.ResponseError(httpResponseStatus: .ok, twitterAPIError: .rateLimitExceeded)
                    }
                    let query = Twitter.API.V2.Status.List.StatusesQuery(
                        maxResults: fetchContext.maxResults ?? 20,
                        nextToken: fetchContext.paginationToken
                    )
                    let response = try await api.twitterListStatuses(
                        list: fetchContext.list,
                        query: query,
                        authenticationContext: fetchContext.authenticationContext
                    )
                    
                    let data = response.value.data ?? []
                    if data.isEmpty {
                        try await fetchContext.managedObjectContext.perform {
                            guard let list = fetchContext.list.object(in: fetchContext.managedObjectContext) else { return }
                            if list.private {
                                throw EmptyState.unableToAccess
                            }
                        }
                    }
                    
                    return .v2(response)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    throw error
                }
            }()
            
            let backInput = response.backInput(fetchContext: fetchContext)
            let nextInput = response.nextInput(fetchContext: fetchContext)
            let result = response.filter(fetchContext: fetchContext)
            
            return .init(
                result: result,
                backInput: backInput.flatMap { .list($0) },
                nextInput: nextInput.flatMap { .list($0) }
            )
        case .mastodon(let fetchContext):
            let query = Mastodon.API.Timeline.TimelineQuery(
                maxID: fetchContext.maxID,
                minID: fetchContext.minID,
                limit: fetchContext.count ?? 20
            )
            let response = try await api.mastodonListStatuses(
                list: fetchContext.list,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let backInput: Input? = {
                guard let minID = response.link?.minID else { return nil }
                let fetchContext = fetchContext.map(minID: minID)
                return .mastodon(fetchContext)
            }()
            let nextInput: Input? = {
                guard let maxID = response.link?.maxID else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: .mastodon(response.value),
                backInput: backInput.flatMap { .list($0) },
                nextInput: nextInput.flatMap { .list($0) }
            )
        }   // end switch
    }
    
}
