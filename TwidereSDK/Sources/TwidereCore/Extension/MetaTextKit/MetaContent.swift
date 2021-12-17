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
        case twitter(string: String, urlMaximumLength: Int = 30, provider: TwitterTextProvider)
        case mastodon(string: String, emojis: MastodonContent.Emojis)
    }
    
    public static func convert(from source: Source) -> MetaContent {
        switch source {
        case .plaintext(let string):
            return PlaintextMetaContent(string: string)
        case .twitter(let string, let urlMaximumLength, let provider):
            let content = TwitterContent(content: string)
            return TwitterMetaContent.convert(
                content: content,
                urlMaximumLength: urlMaximumLength,
                twitterTextProvider: provider
            )
        case .mastodon(let string, let emojis):
            do {
                let content = MastodonContent(content: string, emojis: emojis)
                return try MastodonMetaContent.convert(document: content)
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: string)
            }
        }
    }
}
