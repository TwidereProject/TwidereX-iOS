//
//  TwitterOAuthProvider.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import Foundation
import TwitterSDK

public protocol TwitterAuthorizationContextProvider: AnyObject {
    var oauth: Twitter.AuthorizationContext.OAuth.Context { get }
    var oauth2: Twitter.AuthorizationContext.OAuth2.Context { get }
}
