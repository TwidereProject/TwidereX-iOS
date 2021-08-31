//
//  AuthenticationContext.swift
//  AuthenticationContext
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwitterSDK
import MastodonSDK
import CoreDataStack

enum AuthenticationContext {
    case twitter(authenticationContext: TwitterAuthenticationContext)
    case mastodon(authenticationContext: MastodonAuthenticationContext)
    
    init?(authenticationIndex: AuthenticationIndex) {
        switch authenticationIndex.platform {
        case .twitter:
            guard let authentication = authenticationIndex.twitterAuthentication else { return nil }
            guard let authenticationContext = TwitterAuthenticationContext(authentication: authentication) else { return nil }
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
    var twitterAuthenticationContext: TwitterAuthenticationContext? {
        guard case let .twitter(authenticationContext) = self else { return nil }
        return authenticationContext
    }
    
    var mastodonAuthenticationContext: MastodonAuthenticationContext? {
        guard case let .mastodon(authenticationContext) = self else { return nil }
        return authenticationContext
    }
}
        
struct TwitterAuthenticationContext {
    let authenticationRecord: ManagedObjectRecord<TwitterAuthentication>
    let userID: TwitterUser.ID
    let authorization: Twitter.API.OAuth.Authorization
    
    init?(authentication: TwitterAuthentication) {
        guard let authorization = try? authentication.authorization(appSecret: .default) else { return nil }
        
        self.authenticationRecord = ManagedObjectRecord(objectID: authentication.objectID)
        self.userID = authentication.userID
        self.authorization = authorization
    }
}

struct MastodonAuthenticationContext {
    let authenticationRecord: ManagedObjectRecord<MastodonAuthentication>
    let domain: String
    let userID: MastodonUser.ID
    let authorization: Mastodon.API.OAuth.Authorization
    
    init(authentication: MastodonAuthentication) {
        self.authenticationRecord = ManagedObjectRecord(objectID: authentication.objectID)
        self.domain = authentication.domain
        self.userID = authentication.userID
        self.authorization = Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
    }
}
