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
import TwidereLocalization

extension StatusFetchViewModel {
    public enum Timeline { }
}

extension StatusFetchViewModel.Timeline {
    public enum Kind {
        case home
        case `public`(isLocal: Bool)
        case hashtag(hashtag: String)
        case list(list: ListRecord)
        case search(searchTimelineContext: SearchTimelineContext)
        case user(userTimelineContext: UserTimelineContext)
        
        public var category: String {
            switch self {
            case .home:                     return "home"
            case .public:                   return "public"
            case .hashtag:                  return "hashtag"
            case .list:                     return "list"
            case .search:                   return "search"
            case .user(let context):
                switch context.timelineKind {
                case .status:               return "user|status"
                case .media:                return "user|media"
                case .like:                 return "user|like"
                }
            }
        }
    }   // end enum Kind
}

extension StatusFetchViewModel.Timeline.Kind {

    public class UserTimelineContext {
        public let timelineKind: TimelineKind
        @Published public var userIdentifier: UserIdentifier?
        
        public init(
            timelineKind: TimelineKind,
            userIdentifier: Published<UserIdentifier?>.Publisher?
        ) {
            self.timelineKind = timelineKind
            
            if let userIdentifier = userIdentifier {
                userIdentifier.assign(to: &self.$userIdentifier)
                
            }
        }
        
        public enum TimelineKind {
            case status
            case media
            case like
            
            public var title: String {
                switch self {
                case .status:       return ""
                case .media:        return ""
                case .like:         return L10n.Scene.Likes.title
                }
            }   // end title
        }   // end enum TimelineKind
    }   // end class UserTimelineContext
    
    public class SearchTimelineContext {
        public let timelineKind: TimelineKind
        @Published public var searchText = ""
        
        public init(
            timelineKind: TimelineKind,
            searchText: Published<String>.Publisher?
        ) {
            self.timelineKind = timelineKind
            
            if let searchText = searchText {
                searchText.assign(to: &self.$searchText)
            }
        }
        
        public enum TimelineKind {
            case status
            case media
            
            public var title: String {
                switch self {
                case .status:       return ""
                case .media:        return ""
                }
            }   // end title
        }   // end enum TimelineKind
    }   // end class SearchTimelineContext
    
}

extension StatusFetchViewModel.Timeline {

    public enum Input: Hashable {
        case home(Home.Input)
        case `public`(Public.Input)
        case hashtag(Hashtag.Input)
        case list(List.Input)
        case search(Search.Input)
        case user(User.Input)
    }
    
    public struct Output {
        public let result: StatusFetchViewModel.Result
        public let backInput: Input?
        public let nextInput: Input?
        
        public var hasMore: Bool {
            nextInput != nil
        }
    }
    
}

extension StatusFetchViewModel.Timeline {
    
    public enum Position {
        case top(anchor: StatusRecord?)
        case middle(anchor: StatusRecord)
        case bottom(anchor: StatusRecord)
    }
    
    public class Filter: Hashable {
        
        public var rule: Rule
        
        public init(rule: Rule) {
            self.rule = rule
        }
        
        public static func == (
            lhs: StatusFetchViewModel.Timeline.Filter,
            rhs: StatusFetchViewModel.Timeline.Filter
        ) -> Bool {
            return lhs.rule == rhs.rule
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rule)
        }
        
        public struct Rule: OptionSet, Hashable {
            public let rawValue: Int
            
            static let onlyMedia = Rule(rawValue: 1 << 0)
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public static let empty: Rule = []
        }
        
        public func isIncluded(_ status: Twitter.Entity.V2.Tweet) -> Bool {
            if rule.contains(.onlyMedia) {
                // the repost also contains the mediaKeys. Not needs handle explicitly
                guard let mediaKeys = status.attachments?.mediaKeys, !mediaKeys.isEmpty else { return false }
            }
            
            return true
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
    
    /// Preare `Input` from `FetchContext` for following `fetch`
    /// - Parameter fetchContext: the context info to fetch items
    /// - Returns: `Input` ready for `fetch`
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
                        case .middle(let anchor), .bottom(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .twitter(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
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
                        case .middle(let anchor), .bottom(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        }
                    }(),
                    count: nil,
                    filter: fetchContext.filter
                )))
            }   // end switch fetchContext.authenticationContext
        case .public(let isLocal):
            switch fetchContext.authenticationContext {
            case .twitter:
                throw AppError.ErrorReason.internal(reason: "No public timeline for Twitter")
            case .mastodon(let authenticationContext):
                return await .public(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    minID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        case .middle, .bottom:
                            return nil
                        }
                    }(),
                    maxID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top:
                            return nil
                        case .middle(let anchor), .bottom(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        }
                    }(),
                    count: nil,
                    isLocal: isLocal,
                    filter: fetchContext.filter
                )))
            }
        case .hashtag(let hashtag):
            switch fetchContext.authenticationContext {
            case .twitter(let authenticationContext):
                return .search(.twitter(.init(
                    authenticationContext: authenticationContext,
                    searchText: hashtag,
                    untilID: nil,
                    nextToken: nil,
                    maxResults: nil,
                    filter: fetchContext.filter
                )))
            case .mastodon(let authenticationContext):
                return await .hashtag(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    hashtag: hashtag,
                    minID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        case .middle, .bottom:
                            return nil
                        }
                    }(),
                    maxID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top:
                            return nil
                        case .middle(let anchor), .bottom(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        }
                    }(),
                    count: nil,
                    filter: fetchContext.filter
                )))
            }
        case .list(let list):
            switch fetchContext.authenticationContext {
            case .twitter(let authenticationContext):
                guard case let .twitter(record) = list else {
                    throw AppError.implicit(.internal(reason: "Use invalid list record for Twitter list status lookup"))
                }
                return .list(.twitter(.init(
                    authenticationContext: authenticationContext,
                    list: record,
                    paginationToken: nil,
                    maxResults: nil,
                    filter: fetchContext.filter
                )))
            case .mastodon(let authenticationContext):
                guard case let .mastodon(record) = list else {
                    throw AppError.implicit(.internal(reason: "Use invalid list record for Mastodon list status lookup"))
                }
                return .list(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    list: record,
                    minID: nil,
                    maxID: nil,
                    count: nil,
                    filter: fetchContext.filter
                )))
            }
        case .search(let searchTimelineContext):
            switch fetchContext.authenticationContext {
            case .twitter(let authenticationContext):
                return .search(.twitter(.init(
                    authenticationContext: authenticationContext,
                    searchText: searchTimelineContext.searchText,
                    untilID: nil,
                    nextToken: nil,
                    maxResults: nil,
                    filter: {
                        switch searchTimelineContext.timelineKind {
                        case .media:
                            fetchContext.filter.rule.insert(.onlyMedia)
                            return fetchContext.filter
                        default:
                            return fetchContext.filter
                        }
                    }()
                )))
            case .mastodon(let authenticationContext):
                return .search(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    searchText: searchTimelineContext.searchText,
                    offset: 0,
                    count: nil,
                    filter: {
                        switch searchTimelineContext.timelineKind {
                        case .media:
                            fetchContext.filter.rule.insert(.onlyMedia)
                            return fetchContext.filter
                        default:
                            return fetchContext.filter
                        }
                    }()
                )))
            }
        case .user(let userTimelineContext):
            switch fetchContext.authenticationContext {
            case .twitter(let authenticationContext):
                guard case let .twitter(userIdentifier) = userTimelineContext.userIdentifier else {
                    throw AppError.implicit(.internal(reason: "Use invalid user identifier for user timeline"))
                }
                return .user(.twitter(.init(
                    authenticationContext: authenticationContext,
                    userID: userIdentifier.id,
                    paginationToken: nil,
                    maxResults: nil,
                    filter: {
                        switch userTimelineContext.timelineKind {
                        case .media:
                            fetchContext.filter.rule.insert(.onlyMedia)
                            return fetchContext.filter
                        default:
                            return fetchContext.filter
                        }
                    }(),
                    timelineKind: userTimelineContext.timelineKind
                )))
            case .mastodon(let authenticationContext):
                guard case let .mastodon(userIdentifier) = userTimelineContext.userIdentifier else {
                    throw AppError.implicit(.internal(reason: "Use invalid user identifier for user timeline"))
                }
                return await .user(.mastodon(.init(
                    authenticationContext: authenticationContext,
                    accountID: userIdentifier.id,
                    maxID: {
                        let managedObjectContext = fetchContext.managedObjectContext
                        switch fetchContext.position {
                        case .top:
                            return nil
                        case .middle(let anchor), .bottom(let anchor):
                            return await managedObjectContext.perform {
                                guard case let .mastodon(record) = anchor else { return nil }
                                return record.object(in: managedObjectContext)?.id
                            }
                        }
                    }(),
                    count: nil,
                    filter: {
                        switch userTimelineContext.timelineKind {
                        case .media:
                            fetchContext.filter.rule.insert(.onlyMedia)
                            return fetchContext.filter
                        default:
                            return fetchContext.filter
                        }
                    }(),
                    timelineKind: userTimelineContext.timelineKind
                )))
            }   // end switch
        }
    }
    
    public static func fetch(
        api: APIService,
        input: Input
    ) async throws -> Output {
        switch input {
        case .home(let input):
            return try await Home.fetch(api: api, input: input)
        case .public(let input):
            return try await Public.fetch(api: api, input: input)
        case .hashtag(let input):
            return try await Hashtag.fetch(api: api, input: input)
        case .list(let input):
            return try await List.fetch(api: api, input: input)
        case .search(let input):
            return try await Search.fetch(api: api, input: input)
        case .user(let input):
            return try await User.fetch(api: api, input: input)
        }
    }

}
