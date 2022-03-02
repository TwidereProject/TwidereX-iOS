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
import TwidereCore

extension StatusFetchViewModel.List {

    enum Input {
        case twitter(TwitterFetchContext)
    }
    
    struct Output {
        let result: StatusFetchViewModel.Result
        let nextInput: Input?
        
        var hasMore: Bool {
            nextInput != nil
        }
    }
    
    struct TwitterFetchContext {
        let authenticationContext: TwitterAuthenticationContext
        let list: ManagedObjectRecord<TwitterList>
        let maxResults: Int?
        let nextToken: String?
        
        func map(nextToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                maxResults: maxResults,
                nextToken: nextToken
            )
        }
    }

    static func timeline(context: AppContext, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let query = Twitter.API.V2.Status.List.StatusesQuery(
                maxResults: fetchContext.maxResults ?? 20,
                nextToken: fetchContext.nextToken
            )
            let response = try await context.apiService.twitterListStatuses(
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
        }   // end switch input { }
    }
    
}
