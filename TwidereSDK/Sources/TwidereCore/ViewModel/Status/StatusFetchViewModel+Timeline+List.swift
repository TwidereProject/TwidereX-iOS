//
//  StatusFetchViewModel+Timeline+List.swift
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
    public enum List { }
}

extension StatusFetchViewModel.Timeline.List {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.List", category: "ViewModel")
    
    public enum Input: Hashable {
        case twitter(TwitterFetchContext)
        case mastodon(MastodonFetchContext)
    }
    
    public struct TwitterFetchContext: Hashable {
        public let authenticationContext: TwitterAuthenticationContext
        public let list: ManagedObjectRecord<TwitterList>
        public let paginationToken: String?
        public let maxResults: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            list: ManagedObjectRecord<TwitterList>,
            paginationToken: String?,
            maxResults: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.list = list
            self.paginationToken = paginationToken
            self.maxResults = maxResults
            self.filter = filter
        }
        
        func map(paginationToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                paginationToken: paginationToken,
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
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .twitter(let fetchContext):
            let query = Twitter.API.V2.Status.List.StatusesQuery(
                maxResults: fetchContext.maxResults ?? 20,
                nextToken: fetchContext.paginationToken
            )
            let response = try await api.twitterListStatuses(
                list: fetchContext.list,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let backInput: Input? = {
                guard let nextToken = response.value.meta.previousToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            }()
            let nextInput: Input? = {
                guard let nextToken = response.value.meta.nextToken else { return nil }
                let fetchContext = fetchContext.map(paginationToken: nextToken)
                return .twitter(fetchContext)
            }()
            return .init(
                result: .twitterV2(response.value.data ?? []),
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
