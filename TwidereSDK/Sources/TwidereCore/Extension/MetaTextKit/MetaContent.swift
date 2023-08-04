//
//  MetaContent.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-9-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwitterMeta
import MastodonMeta
import Meta

extension Meta {
    public enum Source {
        case plaintext(string: String)
        case twitter(content: TwitterContent, urlMaximumLength: Int = 30)
        case mastodon(content: MastodonContent)
    }
    
    public static func convert(document source: Source) -> MetaContent {
        switch source {
        case .plaintext(let string):
            return PlaintextMetaContent(string: string)
        case .twitter(let content, let urlMaximumLength):
            return TwitterMetaContent.convert(
                document: content,
                urlMaximumLength: urlMaximumLength,
                twitterTextProvider: SwiftTwitterTextProvider()
            )
        case .mastodon(let content):
            do {
                return try MastodonMetaContent.convert(document: content)
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: content.content)
            }
        }
    }
}
