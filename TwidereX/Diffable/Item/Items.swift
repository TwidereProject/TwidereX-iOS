//
//  Items.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import Foundation
import CoreData
import TwitterAPI
import CoreDataStack

/// Note: update Equatable when change case
enum Item {
    // indexed timeline
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: Attribute)
    case mentionTimelineIndex(objectID: NSManagedObjectID, attribute: Attribute)
    
    // normal list
    case tweet(objectID: NSManagedObjectID)
    case photoTweet(objectID: NSManagedObjectID, attribute: PhotoAttribute)
    case twittertUser(objectID: NSManagedObjectID)
    
    // loader
    case middleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    case bottomLoader
}

extension Item {
    class Attribute: Hashable {
        var separatorLineStyle: SeparatorLineStyle = .indent
        
        static func == (lhs: Item.Attribute, rhs: Item.Attribute) -> Bool {
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
    
    class PhotoAttribute: Hashable {
        let id = UUID()
        let index: Int
        
        public init(index: Int) {
            self.index = index
        }
        
        static func == (lhs: Item.PhotoAttribute, rhs: Item.PhotoAttribute) -> Bool {
            return lhs.index == rhs.index
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.mentionTimelineIndex(let objectIDLeft, _), .mentionTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.tweet(let objectIDLeft), .tweet(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.photoTweet(let objectIDLeft, _), .photoTweet(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.twittertUser(let objectIDLeft), .twittertUser(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.middleLoader(let upperLeft), .middleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.bottomLoader, .bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .homeTimelineIndex(let objectID, _):
            hasher.combine(objectID)
        case .mentionTimelineIndex(let objectID, _):
            hasher.combine(objectID)
        case .tweet(let objectID):
            hasher.combine(objectID)
        case .photoTweet(let objectID, _):
            hasher.combine(objectID)
        case .twittertUser(let objectID):
            hasher.combine(objectID)
        case .middleLoader(let upper):
            hasher.combine(String(describing: Item.middleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: Item.bottomLoader.self))
        }
    }
}
