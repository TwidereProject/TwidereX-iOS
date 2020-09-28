//
//  TimelineItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import Foundation
import CoreData
import TwitterAPI

enum TimelineItem {
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: Attribute)
    case homeTimelineMiddleLoader(upper: Int)
    
    case userTimelineItem(tweet: Twitter.Entity.Tweet)
    
    case bottomLoader
}

extension TimelineItem {
    class Attribute: Hashable {
        var indentSeparatorLine: Bool = true
        
        static func == (lhs: TimelineItem.Attribute, rhs: TimelineItem.Attribute) -> Bool {
            return lhs.indentSeparatorLine == rhs.indentSeparatorLine
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(indentSeparatorLine)
        }
    }
}

extension TimelineItem: Equatable {
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.homeTimelineMiddleLoader(let upperLeft), .homeTimelineMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.bottomLoader, .bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension TimelineItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .homeTimelineIndex(let objectID, _):
            hasher.combine(objectID)
        case .homeTimelineMiddleLoader(let upper):
            hasher.combine(String(describing: TimelineItem.homeTimelineMiddleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: TimelineItem.bottomLoader.self))
        case .userTimelineItem(let tweet):
            hasher.combine(tweet.idStr)
        }
    }
}
