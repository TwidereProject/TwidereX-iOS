//
//  StatusFetchViewModel+Timeline+Hashtag.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum Hashtag { }
}

extension StatusFetchViewModel.Timeline.Hashtag {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.Hashtag", category: "ViewModel")
    
    public enum Input: Hashable {
        case mastodon(MastodonFetchContext)
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let hashtag: String
        public let minID: Mastodon.Entity.Status.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            hashtag: String,
            minID: Mastodon.Entity.Status.ID?,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.hashtag = hashtag
            self.minID = minID
            self.maxID = maxID
            self.count = count
            self.filter = filter
        }
        
        func map(minID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                hashtag: hashtag,
                minID: minID,
                maxID: nil,
                count: count,
                filter: filter
            )
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                hashtag: hashtag,
                minID: nil,
                maxID: maxID,
                count: count,
                filter: filter
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.Hashtag {
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .mastodon(let fetchContext):
            let query = Mastodon.API.Timeline.TimelineQuery(
                maxID: fetchContext.maxID,
                limit: fetchContext.count
            )
            let response = try await api.mastodonHashtagTimeline(
                hashtag: fetchContext.hashtag,
                query: query,
                authenticationContext: fetchContext.authenticationContext
            )
            let backInput: Input? = {
                guard fetchContext.maxID == nil else { return nil }
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
                backInput: backInput.flatMap { .hashtag($0) },
                nextInput: nextInput.flatMap { .hashtag($0) }
            )
        }   // end switch
    }
    
}
