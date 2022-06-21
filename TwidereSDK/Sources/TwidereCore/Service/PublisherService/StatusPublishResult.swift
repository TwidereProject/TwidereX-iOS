//
//  StatusPublishResult.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import TwitterSDK
import MastodonSDK

public enum StatusPublishResult {
    case twitter(Twitter.Response.Content<Twitter.API.V2.Status.PublishContent>)
    case mastodon(Mastodon.Response.Content<Mastodon.Entity.Status>)
}
