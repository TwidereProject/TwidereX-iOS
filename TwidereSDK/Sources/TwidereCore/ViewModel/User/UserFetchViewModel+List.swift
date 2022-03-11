//
//  UserFetchViewModel+List.swift
//  
//
//  Created by MainasuK on 2022-3-11.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK
import CoreDataStack

extension UserFetchViewModel.List {
    
    static let logger = Logger(subsystem: "UserFetchViewModel.List", category: "ViewModel")
    
    public enum Kind {
        case follower
        case member
    }
    
    public enum Input {
        case twitter(TwitterFetchContext)
    }
    
    public struct Output {
        public let result: UserFetchViewModel.Result
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
        public let kind: Kind
        
        public init(
            authenticationContext: TwitterAuthenticationContext,
            list: ManagedObjectRecord<TwitterList>,
            maxResults: Int?,
            nextToken: String?,
            kind: Kind
        ) {
            self.authenticationContext = authenticationContext
            self.list = list
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.kind = kind
        }
        
        func map(nextToken: String) -> TwitterFetchContext {
            return TwitterFetchContext(
                authenticationContext: authenticationContext,
                list: list,
                maxResults: maxResults,
                nextToken: nextToken,
                kind: kind
            )
        }
    }
    
    public struct MastodonFetchContext {
        public let authenticationContext: MastodonAuthenticationContext
        public let searchText: String
        public let offset: Int
        public let count: Int?
        
        public init(authenticationContext: MastodonAuthenticationContext, searchText: String, offset: Int, count: Int?) {
            self.authenticationContext = authenticationContext
            self.searchText = searchText
            self.offset = offset
            self.count = count
        }
        
        func map(offset: Int) -> MastodonFetchContext {
            return MastodonFetchContext(
                authenticationContext: authenticationContext,
                searchText: searchText,
                offset: offset,
                count: count
            )
        }
    }

    public static func list(api: APIService, input: Input) async throws -> Output {
        switch input {
        case .twitter(let fetchContext):
            let response: Twitter.Response.Content<Twitter.API.V2.List.MemberContent> = try await {
                switch fetchContext.kind {
                case .follower:
                    return try await api.twitterListFollower(
                        list: fetchContext.list,
                        query: .init(
                            maxResults: fetchContext.maxResults ?? 50,
                            nextToken: fetchContext.nextToken
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                case .member:
                    return try await api.twitterListMember(
                        list: fetchContext.list,
                        query: .init(
                            maxResults: fetchContext.maxResults ?? 50,
                            nextToken: fetchContext.nextToken
                        ),
                        authenticationContext: fetchContext.authenticationContext
                    )
                }
            }()
            let content = response.value
            return Output(
                result: .twitterV2(content.data ?? []),
                nextInput: {
                    guard let nextToken = content.meta.nextToken else { return nil }
                    let fetchContext = fetchContext.map(nextToken: nextToken)
                    return .twitter(fetchContext)
                }()
            )
        }   // end switch
    }   // end func
    
}
