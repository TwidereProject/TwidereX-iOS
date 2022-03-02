//
//  ListObject.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import CoreDataStack

public enum ListObject: Hashable {
    case twitter(object: TwitterList)
}

extension ListObject {
    public var asRecord: ListRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        }
    }
}
