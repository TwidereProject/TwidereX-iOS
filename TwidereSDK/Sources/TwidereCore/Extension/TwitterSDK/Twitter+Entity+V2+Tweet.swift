//
//  Twitter+Entity+V2+Tweet.swift
//  
//
//  Created by MainasuK on 2023/6/2.
//

import Foundation
import TwitterSDK
import TwitterMeta

extension Twitter.Entity.V2.Tweet {
    public var urlEntities: [TwitterContent.URLEntity] {
        let results = entities?.urls?.map { entity in
            TwitterContent.URLEntity(url: entity.url, expandedURL: entity.expandedURL, displayURL: entity.displayURL)
        }
        return results ?? []
    }
}
