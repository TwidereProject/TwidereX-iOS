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
import TwidereCore

extension ListFetchViewModel.List {

    enum Input {
        case twitterUserOwned(TwitterFetchContext)
        case twitterUserFollowed(TwitterFetchContext)
        case twitterUserListed(TwitterFetchContext)
    }
    
    struct Output {
        let result: ListFetchViewModel.Result
        let nextInput: Input?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let user: ManagedObjectRecord<TwitterUser>
        let maxResults: Int?
        let nextToken: String?
        
        func map(nextToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                user: user,
                maxResults: maxResults,
                nextToken: nextToken
            )
        }
    }

    static func list(context: AppContext, input: Input) async throws -> Output {
        switch input {
        case .twitterUserOwned(let fetchContext):
            let query = Twitter.API.V2.User.List.OwnedListsQuery(
                maxResults: fetchContext.maxResults ?? 50,
                nextToken: fetchContext.nextToken
            )
            let response = try await context.apiService.twitterUserOwnedLists(
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
            let response = try await context.apiService.twitterUserFollowedLists(
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
            let response = try await context.apiService.twitterUserListMemberships(
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
        }   // end switch input { }
    }
    
}
