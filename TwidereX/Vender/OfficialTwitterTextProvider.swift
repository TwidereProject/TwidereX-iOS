//
//  OfficialTwitterTextProvider.swift
//  OfficialTwitterTextProvider
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Meta
import TwitterMeta
import twitter_text

public class OfficialTwitterTextProvider: TwitterTextProvider {
    public func entities(in text: String) -> [TwitterTextProviderEntity] {
        return TwitterText.entities(inText: text).compactMap { entity in
            switch entity.type {
            case .URL:              return .url(range: entity.range)
            case .screenName:       return .screenName(range: entity.range)
            case .hashtag:          return .hashtag(range: entity.range)
            case .listName:         return .listName(range: entity.range)
            case .symbol:           return .symbol(range: entity.range)
            case .tweetChar:        return .tweetChar(range: entity.range)
            case .tweetEmojiChar:   return .tweetEmojiChar(range: entity.range)
            @unknown default:
                assertionFailure()
                return nil
            }
        }
    }
}
