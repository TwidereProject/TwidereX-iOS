//
//  ListFetchViewModel+Owned.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-4.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension ListFetchViewModel.List {

    public enum Input {
        case twitterUserOwned(TwitterFetchContext)
        case twitterUserFollowed(TwitterFetchContext)
        case twitterUserListed(TwitterFetchContext)
        case mastodonUserOwned(MastodonFetchContext)
    }
    
    public struct Output {
        public let result: ListFetchViewModel.Result
        public let nextInput: Input?
        
        public var hasMore: Bool {
            nextInput != nil
        }
    }
    
    public struct TwitterFetchContext {
        public let authenticationContext: TwitterAuthenticationContext
        public let user: ManagedObjectRecord<TwitterUser>
        public let maxResults: Int?
        public let nextToken: String?
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            user: ManagedObjectRecord<TwitterUser>,
            maxResults: Int?,
            nextToken: String?
        ) {
            self.authenticationContext = authenticationContext
            self.user = user
            self.maxResults = maxResults
            self.nextToken = nextToken
        }
        
        func map(nextToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                user: user,
                maxResults: maxResults,
                nextToken: nextToken
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
    
        public init(
            authenticationContext: MastodonAuthenticationContext
        ) {
            self.authenticationContext = authenticationContext
        }
    }

    public static func list(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitterUserOwned(let fetchContext):
            let query = Twitter.API.V2.User.List.OwnedListsQuery(
                maxResults: fetchContext.maxResults ?? 50,
                nextToken: fetchContext.nextToken
            )
            let response = try await api.twitterUserOwnedLists(
                user: fetchContext.user,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let content = response.value
            return Output(
                result: .twitter(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitterUserOwned(fetchContext)
                }()
            )
        case .twitterUserFollowed(let fetchContext):
            let query = Twitter.API.V2.User.List.FollowedListsQuery(
                maxResults: fetchContext.maxResults ?? 50,
                nextToken: fetchContext.nextToken
            )
            let response = try await api.twitterUserFollowedLists(
                user: fetchContext.user,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let content = response.value
            return Output(
                result: .twitter(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitterUserFollowed(fetchContext)
                }()
            )
        case .twitterUserListed(let fetchContext):
            let query = Twitter.API.V2.User.List.ListMembershipsQuery(
                maxResults: fetchContext.maxResults ?? 50,
                nextToken: fetchContext.nextToken
            )
            let response = try await api.twitterUserListMemberships(
                user: fetchContext.user,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let content = response.value
            return Output(
                result: .twitter(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitterUserListed(fetchContext)
                }()
            )
        case .mastodonUserOwned(let fetchContext):
            let response = try await api.mastodonUserOwnedLists(
                authenticationContext: fetchContext.authenticationContext
            )
            let content = response.value
            return Output(
                result: .mastodon(content),
                nextInput: nil 
            )
        }   // end switch input { }
    }
    
}
