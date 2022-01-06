//
//  TrendObject.swift
//  
//
//  Created by MainasuK on 2021-12-28.
//

import Foundation
import TwitterSDK
import MastodonSDK

public enum TrendObject: Hashable {
    case twitter(trend: Twitter.Entity.Trend)
    case mastodon(tag: Mastodon.Entity.Tag)
}

extension TrendObject {
    public var query: String {
        switch self {
        case .twitter(let trend):
            return trend.name
        case .mastodon(let tag):
            return tag.name
        }
    }
}
