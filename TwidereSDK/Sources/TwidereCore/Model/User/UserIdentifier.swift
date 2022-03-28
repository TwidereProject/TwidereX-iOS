//
//  UserIdentifier.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

public enum UserIdentifier: Hashable {
    case twitter(TwitterUserIdentifier)
    case mastodon(MastodonUserIdentifier)
}

public struct TwitterUserIdentifier: Hashable {
    public let id: TwitterUser.ID
    
    public init(id: TwitterUser.ID) {
        self.id = id
    }
}

public struct MastodonUserIdentifier: Hashable {
    public let domain: String
    public let id: MastodonUser.ID
    
    public init(domain: String, id: MastodonUser.ID) {
        self.domain = domain
        self.id = id
    }
}

extension UserIdentifier {
    public init(object: UserObject) {
        switch object {
        case .twitter(let object):
            self = .twitter(.init(id: object.id))
        case .mastodon(let object):
            self = .mastodon(.init(domain: object.domain, id: object.id))
        }
    }
}
