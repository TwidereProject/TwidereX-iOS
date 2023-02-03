//
//  SwiftTwitterTextProvider.swift
//  
//
//  Created by MainasuK on 2023/2/3.
//

import Foundation
import TwitterText
import TwitterMeta

public class SwiftTwitterTextProvider: TwitterTextProvider {
    
    public func parse(text: String) -> TwitterMeta.ParseResult {
        let result = Parser.defaultParser.parseTweet(text: text)
        return .init(
            isValid: result.isValid,
            weightedLength: result.weightedLength,
            maxWeightedLength: Parser.defaultParser.maxWeightedTweetLength(),
            entities: self.entities(in: text)
        )
    }
    
    public func entities(in text: String) -> [TwitterMeta.TwitterTextProviderEntity] {
        return TwitterText.entities(in: text).compactMap { entity in
            switch entity.type {
            case .url:              return .url(range: entity.range)
            case .screenName:       return .screenName(range: entity.range)
            case .hashtag:          return .hashtag(range: entity.range)
            case .listname:         return .listName(range: entity.range)
            case .symbol:           return .symbol(range: entity.range)
            case .tweetChar:        return .tweetChar(range: entity.range)
            case .tweetEmojiChar:   return .tweetEmojiChar(range: entity.range)
            }
        }
    }
    
    public init() { }
    
}
