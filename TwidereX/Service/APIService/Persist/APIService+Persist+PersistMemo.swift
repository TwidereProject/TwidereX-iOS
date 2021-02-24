//
//  APIService+Persist+MemoBook.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-2-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import TwitterAPI

extension APIService.Persist {
    
    class PersistMemo<T, U> {
        
        let status: T
        let children: [PersistMemo<T, U>]
        let memoType: MemoType
        let statusProcessType: ProcessType
        let authorProcessType: ProcessType
        
        enum MemoType {
            case homeTimeline
            case mentionTimeline
            case userTimeline
            case likeList
            case searchList
            case lookUp
            
            case retweet
            case quote
            
            var flag: String {
                switch self {
                case .homeTimeline:     return "H"
                case .mentionTimeline:  return "M"
                case .userTimeline:     return "U"
                case .likeList:         return "L"
                case .searchList:       return "S"
                case .lookUp:           return "LU"
                case .retweet:          return "R"
                case .quote:            return "Q"
                }
            }
        }
        
        enum ProcessType {
            case create
            case merge
            
            var flag: String {
                switch self {
                case .create:   return "+"
                case .merge:    return "~"
                }
            }
        }
        
        init(
            status: T,
            children: [PersistMemo<T, U>],
            memoType: MemoType,
            statusProcessType: ProcessType,
            authorProcessType: ProcessType
        ) {
            self.status = status
            self.children = children
            self.memoType = memoType
            self.statusProcessType = statusProcessType
            self.authorProcessType = authorProcessType
        }
        
    }
    
}

extension APIService.Persist.PersistMemo {
    
    struct Counting {
        var status = Counter()
        var user = Counter()
        
        static func + (left: Counting, right: Counting) -> Counting {
            return Counting(
                status: left.status + right.status,
                user: left.user + right.user
            )
        }
        
        struct Counter {
            var create = 0
            var merge  = 0
            
            static func + (left: Counter, right: Counter) -> Counter {
                return Counter(
                    create: left.create + right.create,
                    merge: left.merge + right.merge
                )
            }
        }
    }
    
    func count() -> Counting {
        var counting = Counting()
        
        switch statusProcessType {
        case .create:       counting.status.create += 1
        case .merge:        counting.status.merge += 1
        }
        
        switch authorProcessType {
        case .create:       counting.user.create += 1
        case .merge:        counting.user.merge += 1
        }
        
        for child in children {
            let childCounting = child.count()
            counting = counting + childCounting
        }
        
        return counting
    }
    
}

extension APIService.Persist.PersistMemo where T == Tweet, U == TwitterUser {
    
    static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        requestTwitterUserID: TwitterUser.ID,
        entity: Twitter.Entity.Tweet,
        memoType: MemoType,
        tweetCache: APIService.Persist.PersistCache<T>?,
        userCache: APIService.Persist.PersistCache<U>?,
        networkDate: Date,
        log: OSLog
    ) -> APIService.Persist.PersistMemo<T, U> {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "finish process tweet %{public}s", entity.idStr)
        }
        
        // build tree
        let retweetMemo = entity.retweetedStatus.flatMap { entity -> APIService.Persist.PersistMemo<T, U> in
            createOrMergeTweet(
                into: managedObjectContext,
                for: requestTwitterUser,
                requestTwitterUserID: requestTwitterUserID,
                entity: entity,
                memoType: .retweet,
                tweetCache: tweetCache,
                userCache: userCache,
                networkDate: networkDate,
                log: log
            )
        }
        let quoteMemo = entity.quotedStatus.flatMap { entity -> APIService.Persist.PersistMemo<T, U> in
            createOrMergeTweet(
                into: managedObjectContext,
                for: requestTwitterUser,
                requestTwitterUserID: requestTwitterUserID,
                entity: entity,
                memoType: .quote,
                tweetCache: tweetCache,
                userCache: userCache,
                networkDate: networkDate,
                log: log
            )
        }
        let children = [retweetMemo, quoteMemo].compactMap { $0 }

        let (tweet, isTweetCreated, isTwitterUserCreated) = APIService.CoreData.createOrMergeTweet(
            into: managedObjectContext,
            for: requestTwitterUser,
            entity: entity,
            tweetCache: tweetCache,
            userCache: userCache,
            networkDate: networkDate,
            log: log
        )
        let memo = APIService.Persist.PersistMemo<T, U>(
            status: tweet,
            children: children,
            memoType: memoType,
            statusProcessType: isTweetCreated ? .create : .merge,
            authorProcessType: isTwitterUserCreated ? .create : .merge
        )
        
        switch (memo.statusProcessType, memoType) {
        case (.create, .homeTimeline), (.merge, .homeTimeline):
            let timelineIndex = tweet.timelineIndexes?
                .first { $0.userID == requestTwitterUserID }
            if timelineIndex == nil {
                let timelineIndexProperty = TimelineIndex.Property(userID: requestTwitterUserID, platform: .twitter, createdAt: entity.createdAt)
                let timelineIndex = TimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty)
                // make it indexed
                tweet.mutableSetValue(forKey: #keyPath(Tweet.timelineIndexes)).add(timelineIndex)
            } else {
                // enity already in home timeline
            }
        case (.create, .mentionTimeline), (.merge, .mentionTimeline):
            let mentionTimelineIndex = tweet.mentionTimelineIndexes?
                .first { $0.userID == requestTwitterUserID }
            if mentionTimelineIndex == nil {
                let mentionTimelineIndexProperty = MentionTimelineIndex.Property(userID: requestTwitterUserID, platform: .twitter, createdAt: entity.createdAt)
                let mentionTimelineIndex = MentionTimelineIndex.insert(into: managedObjectContext, property: mentionTimelineIndexProperty)
                // make it indexed
                tweet.mutableSetValue(forKey: #keyPath(Tweet.mentionTimelineIndexes)).add(mentionTimelineIndex)
            } else {
                // enity already in mention timeline
            }
        default:
            break
        }
        
        return memo
    }
    
    func log(indentLevel: Int = 0) -> String {
        let indent = Array(repeating: "    ", count: indentLevel).joined()
        let tweetPreview = status.text.prefix(32).replacingOccurrences(of: "\n", with: " ")
        let message = "\(indent)[\(statusProcessType.flag)\(memoType.flag)](\(status.id)) [\(authorProcessType.flag)](\(status.author.id))@\(status.author.name) ~> \(tweetPreview)"
        
        var childrenMessages: [String] = []
        for child in children {
            childrenMessages.append(child.log(indentLevel: indentLevel + 1))
        }
        let result = [[message] + childrenMessages]
            .flatMap { $0 }
            .joined(separator: "\n")
        
        return result
    }
    
}

