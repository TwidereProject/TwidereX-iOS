//
//  Twitter+AuthorizationContext.swift
//  
//
//  Created by MainasuK on 2022-4-24.
//

import Foundation

extension Twitter {
    public enum AuthorizationContext {
        case oauth(OAuth.Context)
        case oauth2(OAuth2.Context)
    }
}
