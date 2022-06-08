//
//  StatusFetchViewModel+Timeline.swift
//  
//
//  Created by MainasuK on 2022-6-6.
//

import os.log
import CoreData
import Foundation
import TwitterSDK
import MastodonSDK

extension StatusFetchViewModel {
    public enum Timeline { }
}

extension StatusFetchViewModel.Timeline {
    
    public enum Kind {
        case home
        case federated(local: Bool)
        case userPost(userIdentifier: UserIdentifier)
        case userMedia(userIdentifier: UserIdentifier)
        case userLike(userIdentifier: UserIdentifier)
    }
    
    public enum Input {
        case home(Home.Input)
        // TODO:
    }
    
    public struct Output {
        public let result: StatusFetchViewModel.Result
        public let nextInput: Input?
        
        public var hasMore: Bool {
            nextInput != nil
        }
    }
    
    public enum Position {
        case top
        case middle(anchor: StatusRecord)
        case bottom
    }
    
    public struct Filter {
        public let rule: Rule
        
        public init(rule: Rule) {
            self.rule = rule
        }
        
        public struct Rule: OptionSet {
            public let rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public static let empty: Rule = []
            // TODO:
        }
    }
    
}

extension StatusFetchViewModel.Timeline {
    
    public struct FetchContext {
        public let managedObjectContext: NSManagedObjectContext
        public let authenticationContext: AuthenticationContext
        public let kind: Kind
        public let position: Position
        public let filter: Filter
        
        public init(
            managedObjectContext: NSManagedObjectContext,
            authenticationContext: AuthenticationContext,
            kind: Kind,
            position: StatusFetchViewModel.Timeline.Position,
            filter: StatusFetchViewModel.Timeline.Filter
        ) {
            self.managedObjectContext = managedObjectContext
            self.authenticationContext = authenticationContext
            self.kind = kind
            self.position = position
            self.filter = filter
        }
        
        
    }

    public static func prepare(fetchContext: FetchContext) async throws -> Input {
        switch fetchContext.kind {
        case .home:
            switch fetchContext.authenticationContext {
            case .twitter(let authenticationContext):
                return await .home(.twitter(.init(
                    authenticationContext: authenticationContext,
                    untilID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top:
                            return nil
                        case .middle(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .twitter(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        case .bottom:
                            assertionFailure()
                            return nil
                        }
                    }(),
                    maxResults: nil,
                    filter: fetchContext.filter
                )))
            case .mastodon(let authenticationContext):
                return await .home(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    maxID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top:
                            return nil
                        case .middle(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        case .bottom:
                            assertionFailure()
                            return nil
                        }
                    }(),
                    count: nil,
                    filter: fetchContext.filter)))
            }   // end switch fetchContext.authenticationContext
        default:
            fatalError()
        }
    }
    
    public static func fetch(
        api: APIService,
        input: Input
    ) async throws -> Output {
        switch input {
        case .home(let input):
            return try await Home.fetch(api: api, input: input)
        default:
            fatalError()
        }
    }
    
//    public static func homeTimeline(api: APIService, input: Input) async throws -> Output {
//        switch input {
//        case .twitter(let fetchContext):
//            let authenticationContext = fetchContext.authenticationContext
//            let response = try await api.twitterHomeTimelineV1(
//                maxID: fetchContext.maxID,
//                count: fetchContext.maxResults ?? 100,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = response.value.last?.idStr else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return .twitter(fetchContext)
//            }()
//            return Output(
//                result: .twitter(response.value),
//                nextInput: nextInput
//            )
//        case .mastodon(let fetchContext):
//            let authenticationContext = fetchContext.authenticationContext
//            let response = try await api.mastodonHomeTimeline(
//                maxID: fetchContext.maxID,
//                count: fetchContext.count ?? 100,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = response.value.last?.id else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return .mastodon(fetchContext)
//            }()
//            return Output(
//                result: .mastodon(response.value),
//                nextInput: nextInput
//            )
//        }
//    }
//
//    public static func publicTimeline(api: APIService, input: Input) async throws -> Output {
//        switch input {
//        case .twitter(let fetchContext):
//            assertionFailure("Invalid entry")
//            throw AppError.implicit(.badRequest)
//        case .mastodon(let fetchContext):
//            let authenticationContext = fetchContext.authenticationContext
//            let response = try await api.mastodonPublicTimeline(
//                local: fetchContext.local ?? false,
//                maxID: fetchContext.maxID,
//                count: fetchContext.count ?? 100,
//                authenticationContext: authenticationContext
//            )
//            let _maxID = response.link?.maxID
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID) || _maxID == nil || _maxID == fetchContext.maxID
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = _maxID else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return .mastodon(fetchContext)
//            }()
//            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): hasMore: \(!noMore)")
//            return Output(
//                result: .mastodon(response.value),
//                nextInput: nextInput
//            )
//        }
//    }
//
//    public static func userTimeline(api: APIService, input: Input) async throws -> Output {
//        switch input {
//        case .twitter(let fetchContext):
//            guard let userID = fetchContext.userIdentifier?.id else {
//                throw AppError.implicit(.badRequest)
//            }
//            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
//                count: fetchContext.maxResults ?? 100,
//                userID: userID,
//                maxID: fetchContext.maxID,
//                excludeReplies: fetchContext.excludeReplies
//            )
//            let authenticationContext = fetchContext.authenticationContext
//            let response = try await api.twitterUserTimeline(
//                query: query,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = response.value.last?.idStr else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return .twitter(fetchContext)
//            }()
//            return Output(
//                result: .twitter(response.value),
//                nextInput: nextInput
//            )
//        case .mastodon(let fetchContext):
//            guard let accountID = fetchContext.userIdentifier?.id else {
//                throw AppError.implicit(.badRequest)
//            }
//            let authenticationContext = fetchContext.authenticationContext
//            let query = Mastodon.API.Account.AccountStatusesQuery(
//                maxID: fetchContext.maxID,
//                sinceID: nil,
//                excludeReplies: fetchContext.excludeReplies,
//                excludeReblogs: fetchContext.excludeReblogs,
//                onlyMedia: fetchContext.onlyMedia,
//                limit: fetchContext.count ?? 100
//            )
//            let response = try await api.mastodonUserTimeline(
//                accountID: accountID,
//                query: query,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].id == fetchContext.maxID)
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = response.value.last?.id else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return .mastodon(fetchContext)
//            }()
//            return Output(
//                result: .mastodon(response.value),
//                hasMore: !noMore,
//                nextInput: nextInput
//            )
//        }
//    }
//
//    public static func likeTimeline(api: APIService, input: Input) async throws -> Output {
//        switch input.fetchContext {
//        case .twitter(let fetchContext):
//            guard let userID = fetchContext.userIdentifier?.id else {
//                throw AppError.implicit(.badRequest)
//            }
//            let authenticationContext = fetchContext.authenticationContext
//            let query = Twitter.API.Statuses.Timeline.TimelineQuery(
//                count: fetchContext.count ?? 100,
//                userID: userID,
//                maxID: fetchContext.maxID
//            )
//            let response = try await api.twitterLikeTimeline(
//                query: query,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
//            let nextInput: Input? = {
//                if noMore { return nil }
//                guard let maxID = response.value.last?.idStr else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return Input(fetchContext: .twitter(fetchContext))
//            }()
//            return Output(
//                result: .twitter(response.value),
//                hasMore: !noMore,
//                nextInput: nextInput
//            )
//        case .mastodon(let fetchContext):
//            let authenticationContext = fetchContext.authenticationContext
//            let query = Mastodon.API.Favorite.FavoriteStatusesQuery(
//                limit: fetchContext.count ?? 100,
//                maxID: fetchContext.maxID
//            )
//            let response = try await api.mastodonLikeTimeline(
//                query: query,
//                authenticationContext: authenticationContext
//            )
//            let noMore = response.link?.maxID == nil
//            let nextInput: Input? = {
//                guard let maxID = response.link?.maxID else { return nil }
//                let fetchContext = fetchContext.map(maxID: maxID)
//                return Input(fetchContext: .mastodon(fetchContext))
//            }()
//            return Output(
//                result: .mastodon(response.value),
//                hasMore: !noMore,
//                nextInput: nextInput
//            )
//        }
//    }
}
