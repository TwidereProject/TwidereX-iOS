//
//  ListObject.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import CoreDataStack

public enum ListObject: Hashable {
    case twitter(object: TwitterList)
    case mastodon(object: MastodonList)
}

extension ListObject {
    public var asRecord: ListRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            return .mastodon(record: .init(objectID: object.objectID))
        }
    }
}

extension ListObject {
    public var owner: UserObject {
        switch self {
        case .twitter(let object):
            return .twitter(object: object.owner)
        case .mastodon(let object):
            return .mastodon(object: object.owner)
        }
    }
}
