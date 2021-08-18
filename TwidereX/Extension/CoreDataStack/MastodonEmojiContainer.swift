//
//  MastodonEmojiContainer.swift
//  MastodonEmojiContainer
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK

protocol MastodonEmojiContainer {
    var emojisData: Data? { get }
}

extension MastodonEmojiContainer {
    
    static func encode(emojis: [Mastodon.Entity.Emoji]) -> Data? {
        return try? JSONEncoder().encode(emojis)
    }
    
    var emojis: [Mastodon.Entity.Emoji]? {
        guard let data = emojisData else { return nil }
        return try? JSONDecoder().decode([Mastodon.Entity.Emoji].self, from: data)
    }

}
