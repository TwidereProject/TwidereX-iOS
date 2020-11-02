//
//  TimelineItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import Foundation
import CoreData
import TwitterAPI
import CoreDataStack

/// Note: update Equatable when change case
enum TimelineItem {
    
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: Attribute)
    case homeTimelineMiddleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    
    case userTimelineItem(objectID: NSManagedObjectID)
    
    case searchTimelineItem(objectID: NSManagedObjectID)
    
    case bottomLoader
}

extension TimelineItem {
    class Attribute: Hashable {
        var separatorLineStyle: SeparatorLineStyle = .indent
        
        static func == (lhs: TimelineItem.Attribute, rhs: TimelineItem.Attribute) -> Bool {
            return lhs.separatorLineStyle == rhs.separatorLineStyle
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(separatorLineStyle)
        }
        
        enum SeparatorLineStyle {
            case indent     // alignment to name label
            case expand     // alignment to table view two edges
            case normal     // alignment to readable guideline
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
        case (.userTimelineItem(let objectIDLeft), .userTimelineItem(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.searchTimelineItem(let objectIDLeft), .searchTimelineItem(let objectIDRight)):
            return objectIDLeft == objectIDRight
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
        case .userTimelineItem(let objectID):
            hasher.combine(objectID)
        case .searchTimelineItem(let objectID):
            hasher.combine(objectID)
        case .bottomLoader:
            hasher.combine(String(describing: TimelineItem.bottomLoader.self))
        }
    }
}
