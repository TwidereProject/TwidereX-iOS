//
//  TimelineItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import Foundation
import CoreData

enum TimelineItem: Hashable {
    case homeTimelineIndex(NSManagedObjectID)
    case homeTimelineMiddleLoader(upper: Int)
    case bottomLoader
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .homeTimelineIndex(let objectID):
            hasher.combine(objectID)
        case .homeTimelineMiddleLoader(let upper):
            hasher.combine(String(describing: TimelineItem.homeTimelineMiddleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: TimelineItem.bottomLoader.self))
        }
    }
}
