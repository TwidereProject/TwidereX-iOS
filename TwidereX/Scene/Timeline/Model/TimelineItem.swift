//
//  TimelineItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import Foundation
import CoreData

enum TimelineItem {
    case homeTimelineIndex(objectID: NSManagedObjectID, expandStatus: ExpandStatus)
    case homeTimelineMiddleLoader(upper: Int)
    case bottomLoader
}

extension TimelineItem {
    class ExpandStatus: Hashable {
        var isExpand: Bool = false
        
        static func == (lhs: TimelineItem.ExpandStatus, rhs: TimelineItem.ExpandStatus) -> Bool {
            return lhs.isExpand == rhs.isExpand
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isExpand)
        }
    }
}

extension TimelineItem: Equatable {
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, let expandStatusLeft), .homeTimelineIndex(let objectIDRight, let expandStatusRight)):
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
        }
    }
}
