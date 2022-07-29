//
//  AuthenticationContext.swift
//  AuthenticationContext
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import TwidereCommon
import TwitterSDK
import MastodonSDK

public enum AuthenticationContext: Hashable {
    case twitter(authenticationContext: TwitterAuthenticationContext)
    case mastodon(authenticationContext: MastodonAuthenticationContext)
    
    public init?(authenticationIndex: AuthenticationIndex, secret: AppSecret.Secret) {
        switch authenticationIndex.platform {
        case .twitter:
            guard let authentication = authenticationIndex.twitterAuthentication else { return nil }
            guard let authenticationContext = TwitterAuthenticationContext(authentication: authentication, secret: secret) else { return nil }
            self = .twitter(authenticationContext: authenticationContext)
        case .mastodon:
            guard let authentication = authenticationIndex.mastodonAuthentication else { return nil }
            let authenticationContext = MastodonAuthenticationContext(authentication: authentication)
            self = .mastodon(authenticationContext: authenticationContext)
        case .none:
            assertionFailure()
            return nil
        }
    }
}

extension AuthenticationContext {
    public var twitterAuthenticationContext: TwitterAuthenticationContext? {
        guard case let .twitter(authenticationContext) = self else { return nil }
        return authenticationContext
    }
    
    public var mastodonAuthenticationContext: MastodonAuthenticationContext? {
        guard case let .mastodon(authenticationContext) = self else { return nil }
        return authenticationContext
    }
}

extension AuthenticationContext {
    public func user(in managedObjectContext: NSManagedObjectContext) -> UserObject? {
        switch self {
        case .twitter(let authenticationContext):
            return authenticationContext.authenticationRecord.object(in: managedObjectContext)
                .flatMap { UserObject.twitter(object: $0.user) }
        case .mastodon(let authenticationContext):
            return authenticationContext.authenticationRecord.object(in: managedObjectContext)
                .flatMap { UserObject.mastodon(object: $0.user) }
        }
    }
}

extension AuthenticationContext {
    public var userIdentifier: UserIdentifier {
        switch self {
        case .twitter(let authenticationContext):
            return .twitter(.init(id: authenticationContext.userID))
        case .mastodon(let authenticationContext):
            return .mastodon(.init(domain: authenticationContext.domain, id: authenticationContext.userID))
        }
    }
}

extension AuthenticationContext {
    public var platform: Platform {
        switch self {
        case .twitter:      return .twitter
        case .mastodon:     return .mastodon
        }
    }
}
        
public struct TwitterAuthenticationContext: Hashable {
    public let authenticationRecord: ManagedObjectRecord<TwitterAuthentication>
    public let userID: TwitterUser.ID
    public let authorization: Twitter.API.OAuth.Authorization
    public let authorizationV2: Twitter.API.V2.OAuth2.Authorization?
    
    public init?(
        authentication: TwitterAuthentication,
        secret: AppSecret.Secret
    ) {
        guard let authorization = try? authentication.authorization(secret: secret) else { return nil }
        
        self.authenticationRecord = ManagedObjectRecord(objectID: authentication.objectID)
        self.userID = authentication.userID
        self.authorization = authorization
        self.authorizationV2 = try? authentication.authorizationV2(secret: secret)
    }
}

public struct MastodonAuthenticationContext: Hashable {
    public let authenticationRecord: ManagedObjectRecord<MastodonAuthentication>
    public let domain: String
    public let userID: MastodonUser.ID
    public let authorization: Mastodon.API.OAuth.Authorization
    
    public init(authentication: MastodonAuthentication) {
        self.authenticationRecord = ManagedObjectRecord(objectID: authentication.objectID)
        self.domain = authentication.domain
        self.userID = authentication.userID
        self.authorization = Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
    }
}
