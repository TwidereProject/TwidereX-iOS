//
//  UserObject.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwidereCommon

public enum UserObject: Hashable {
    case twitter(object: TwitterUser)
    case mastodon(object: MastodonUser)
}

extension UserObject {
    public var asRecord: UserRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            return .mastodon(record: .init(objectID: object.objectID))
        }
    }
    
    public var userIdentifer: UserIdentifier {
        switch self {
        case .twitter(let object):
            return .twitter(.init(id: object.id))
        case .mastodon(let object):
            return .mastodon(.init(domain: object.domain, id: object.id))
        }
    }
    
    public var authenticationContext: AuthenticationContext? {
        switch self {
        case .twitter(let object):
            return object.twitterAuthentication.flatMap {
                AuthenticationContext(authenticationIndex: $0.authenticationIndex, secret: AppSecret.default.secret)
            }
        case .mastodon(let object):
            return object.mastodonAuthentication.flatMap {
                AuthenticationContext(authenticationIndex: $0.authenticationIndex, secret: AppSecret.default.secret)
            }
        }
    }
    
    public var notifications: Set<MastodonNotification> {
        switch self {
        case .twitter:
            return []
        case .mastodon(let object):
            return object.notifications
        }
    }
}

extension UserObject {
    public var name: String {
        switch self {
        case .twitter(let object):
            return object.name
        case .mastodon(let object):
            return object.name
        }
    }
    
    /// - Twitter: `@username`
    /// - Mastodon: `@username@domain.com`
    public var username: String {
        switch self {
        case .twitter(let object):
            return object.username
        case .mastodon(let object):
            return object.acctWithDomain
        }
    }
    
    public var avatarURL: URL? {
        switch self {
        case .twitter(let object):
            return object.avatarImageURL()
        case .mastodon(let object):
            return object.avatar.flatMap { URL(string: $0) }
        }
    }
}
