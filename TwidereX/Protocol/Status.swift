//
//  Status.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import Meta
import TwitterMeta
import twitter_text

protocol Status {
    var account: User { get }

    var repost: Status? { get }

    var content: String { get }
    var createdAt: Date { get }

    var metaContent: MetaContent { get }
}

extension Tweet: Status {
    var account: User { retweet?.author ?? author }
    var repost: Status? { retweet }
    var content: String { text }

    var metaContent: MetaContent {
        let twitterContent = TwitterContent(content: content)
        return TwitterMetaContent.convert(
            content: twitterContent,
            urlMaximumLength: 18,
            twitterTextProvider: OfficialTwitterTextProvider()
        )
    }
}

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
