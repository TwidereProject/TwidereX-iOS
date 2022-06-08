//
//  StatusFetchViewModel+List.swift
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

extension StatusFetchViewModel {
    public enum List { }
}

extension StatusFetchViewModel.List {

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
        public let list: ManagedObjectRecord<TwitterList>
        public let maxResults: Int?
        public let nextToken: String?
        
        public init(authenticationContext: TwitterAuthenticationContext, list: ManagedObjectRecord<TwitterList>, maxResults: Int?, nextToken: String?) {
            self.authenticationContext = authenticationContext
            self.list = list
            self.maxResults = maxResults
            self.nextToken = nextToken
        }
        
        func map(nextToken: Twitter.Entity.V2.Tweet.ID) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                maxResults: maxResults,
                nextToken: nextToken
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let list: ManagedObjectRecord<MastodonList>
        public let maxID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        
        public init(authenticationContext: MastodonAuthenticationContext, list: ManagedObjectRecord<MastodonList>, maxID: Mastodon.Entity.Status.ID?, limit: Int?) {
            self.authenticationContext = authenticationContext
            self.list = list
            self.maxID = maxID
            self.limit = limit
        }
        
        func map(maxID: Mastodon.Entity.Status.ID) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                maxID: maxID,
                limit: limit
            )
        }
    }

    public static func timeline(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let query = Twitter.API.V2.Status.List.StatusesQuery(
                maxResults: fetchContext.maxResults ?? 20,
                nextToken: fetchContext.nextToken
            )
            let response = try await api.twitterListStatuses(
                list: fetchContext.list,
                query: query,
                authenticationContext: fetchContext.authenticationContext
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
            let query = Mastodon.API.Timeline.TimelineQuery(
                maxID: fetchContext.maxID,
                limit: fetchContext.limit ?? 20
            )
            let response = try await api.mastodonListStatuses(
                list: fetchContext.list,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let content = response.value
            return Output(
                result: .mastodon(content),
                nextInput: {
                    guard let maxID = response.link?.maxID else { return nil }
                    guard maxID != fetchContext.maxID else { return nil }
                    let fetchContext = fetchContext.map(maxID: maxID)
                    return .mastodon(fetchContext)
                }()
            )
        }   // end switch input { }
    }
    
}
