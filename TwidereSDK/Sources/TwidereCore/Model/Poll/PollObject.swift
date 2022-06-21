//
//  PollObject.swift
//  
//
//  Created by MainasuK on 2022-6-10.
//

import Foundation
import CoreDataStack

public enum PollObject: Hashable {
    case twitter(object: TwitterPoll)
    case mastodon(object: MastodonPoll)
}

extension PollObject {
    public var updatedAt: Date {
        switch self {
        case .twitter(let object):
            return object.updatedAt
        case .mastodon(let object):
            return object.updatedAt
        }
    }
    
    public var isClosed: Bool {
        switch self {
        case .twitter(let object):
            return object.votingStatus == .closed
        case .mastodon(let object):
            return object.expired
        }
    }
}

extension PollObject {
    public var needsUpdate: Bool {
        guard !isClosed else { return false }
        
        let now = Date()
        let timeIntervalSinceUpdate = now.timeIntervalSince(updatedAt)
        #if DEBUG
        let autoRefreshTimeInterval: TimeInterval = 3 // speedup testing
        #else
        let autoRefreshTimeInterval: TimeInterval = 30
        #endif
        
        return timeIntervalSinceUpdate > autoRefreshTimeInterval
    }
}
