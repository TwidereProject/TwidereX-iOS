//
//  TwitterOAuthProvider.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import Foundation
import TwitterSDK

public protocol TwitterOAuthProvider: AnyObject {
    var oauth: Twitter.API.OAuth.RequestTokenQueryContext { get }
    // func oauth2() ->
}
