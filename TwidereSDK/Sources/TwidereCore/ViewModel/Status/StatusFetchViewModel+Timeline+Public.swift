//
//  StatusFetchViewModel+Timeline+Public.swift
//  
//
//  Created by MainasuK on 2022-6-13.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel.Timeline {
    public enum Public { }
}

extension StatusFetchViewModel.Timeline.Public {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel.Timeline.Public", category: "ViewModel")
    
    public enum Input: Hashable {
        case mastodon(MastodonFetchContext)
    }
    
    public struct MastodonFetchContext: Hashable {
        public let authenticationContext: MastodonAuthenticationContext
        public let minID: Mastodon.Entity.Status.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let count: Int?
        public let isLocal: Bool
        public let filter: StatusFetchViewModel.Timeline.Filter
        
        public init(
            authenticationContext: MastodonAuthenticationContext,
            minID: Mastodon.Entity.Status.ID?,
            maxID: Mastodon.Entity.Status.ID?,
            count: Int?,
            isLocal: Bool,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.authenticationContext = authenticationContext
            self.minID = minID
            self.maxID = maxID
            self.count = count
            self.isLocal = isLocal
            self.filter = filter
        }
        
        func map(minID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                minID: minID,
                maxID: nil,
                count: count,
                isLocal: isLocal,
                filter: filter
            )
        }
        
        func map(maxID: Mastodon.Entity.Status.ID?) -> MastodonFetchContext {
            MastodonFetchContext(
                authenticationContext: authenticationContext,
                minID: nil,
                maxID: maxID,
                count: count,
                isLocal: isLocal,
                filter: filter
            )
        }
    }
    
}

extension StatusFetchViewModel.Timeline.Public {
    
    public static func fetch(api: APIService, input: Input) async throws -> StatusFetchViewModel.Timeline.Output {
        switch input {
        case .mastodon(let fetchContext):
            let response = try await api.mastodonPublicTimeline(
                local: fetchContext.isLocal,
                maxID: fetchContext.maxID,
                count: fetchContext.count ?? 50,
                authenticationContext: fetchContext.authenticationContext
            )
            let backInput: Input? = {
                guard fetchContext.maxID == nil else { return nil }
                guard let minID = response.link?.minID else { return nil }
                let fetchContext = fetchContext.map(minID: minID)
                return .mastodon(fetchContext)
            }()
            let nextInput: Input? = {
                guard let maxID = response.value.last?.id else { return nil }
                let fetchContext = fetchContext.map(maxID: maxID)
                return .mastodon(fetchContext)
            }()
            return .init(
                result: .mastodon(response.value),
                backInput: backInput.flatMap { .public($0) },
                nextInput: nextInput.flatMap { .public($0) }
            )
        }
    }
    
}
