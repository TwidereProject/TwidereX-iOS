//
//  MastodonEmojiContainer.swift
//  MastodonEmojiContainer
//
//  Created by Cirno MainasuK on 2021-9-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK
import CoreDataStack

protocol MastodonEmojiContainer {
    var emojis: [Mastodon.Entity.Emoji]? { get }
}

extension MastodonEmojiContainer {
    var mastodonEmojis: [MastodonEmoji] {
        return emojis.flatMap { emojis in
            emojis.map { MastodonEmoji(emoji: $0) }
        } ?? []
    }
}

extension Mastodon.Entity.Account: MastodonEmojiContainer { }
