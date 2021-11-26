//
//  StatusPublishResult.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import TwitterSDK

public enum StatusPublishResult {
    case twitter(Twitter.Response.Content<Twitter.Entity.Tweet>)
}
