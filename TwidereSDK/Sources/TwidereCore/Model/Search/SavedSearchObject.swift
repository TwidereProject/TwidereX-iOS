//
//  SavedSearchObject.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation
import CoreDataStack

public enum SavedSearchObject: Hashable {
    case twitter(object: TwitterSavedSearch)
}

extension SavedSearchObject {
    public var asRecord: SavedSearchRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        }
    }
}

extension SavedSearchObject {

    public var query: String {
        switch self {
        case .twitter(let object):
            return object.query
        }
    }

}
