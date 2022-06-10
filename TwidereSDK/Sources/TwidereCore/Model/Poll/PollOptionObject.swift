//
//  PollOptionObject.swift
//  
//
//  Created by MainasuK on 2022-6-10.
//

import Foundation
import CoreDataStack

public enum PollOptionObject: Hashable {
    case twitter(object: TwitterPollOption)
    case mastodon(object: MastodonPollOption)
}

extension PollOptionObject {
    public var asRecord: PollOptionRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            return .mastodon(record: .init(objectID: object.objectID))
        }
    }
}

extension PollOptionObject {
    public var poll: PollObject {
        switch self {
        case .twitter(let object):
            return .twitter(object: object.poll)
        case .mastodon(let object):
            return .mastodon(object: object.poll)
        }
    }
}

extension PollOptionObject {
    public var index: Int {
        switch self {
        case .twitter(let object):
            return Int(object.position - 1)
        case .mastodon(let object):
            return Int(object.index)
        }
    }
    
    public var title: String {
        switch self {
        case .twitter(let object):
            return object.label
        case .mastodon(let object):
            return object.title
        }
    }
    
    public var isSelected: Bool {
        switch self {
        case .twitter:
            return false
        case .mastodon(let object):
            return object.isSelected
        }
    }
}
