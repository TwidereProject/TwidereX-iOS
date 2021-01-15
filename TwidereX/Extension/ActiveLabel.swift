//
//  ActiveLabel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel
import twitter_text

extension ActiveLabel {
    
    enum Style {
        case `default`
        case timelineHeaderView
    }
    
    convenience init(style: Style) {
        self.init()
    
        switch style {
        case .default:
            urlMaximumLength = 30
            font = .preferredFont(forTextStyle: .body)
            textColor = UIColor.label.withAlphaComponent(0.8)
        case .timelineHeaderView:
            font = .preferredFont(forTextStyle: .footnote)
            textColor = .secondaryLabel
        }
        
        numberOfLines = 0
        mentionColor = Asset.Colors.hightLight.color
        hashtagColor = Asset.Colors.hightLight.color
        URLColor = Asset.Colors.hightLight.color
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    }
    
}

extension ActiveLabel {
    
    func configure(with twitterText: String) {
        let results = ActiveLabel.parse(tweet: twitterText, urlMaximumLength: urlMaximumLength ?? 30)
        activeEntities.removeAll()
        text = results.trimmedTweet
        activeEntities = results.activeEntities
    }
    
}

extension ActiveLabel {
    
    struct TweetParseResult {
        let originalTweet: String
        let trimmedTweet: String
        let activeEntities: [ActiveEntity]
    }
    
    static func parse(tweet: String, urlMaximumLength: Int) -> TweetParseResult {
        var activeEntities: [ActiveEntity] = []
        let twitterTextEntities = TwitterText.entities(inText: tweet)
        for twitterTextEntity in twitterTextEntities {
            switch twitterTextEntity.type {
            case .URL:
                if let text = tweet.string(in: twitterTextEntity.range) {
                    let trimmed = text.trim(to: urlMaximumLength)
                    activeEntities.append(ActiveEntity(range: twitterTextEntity.range, type: .url(original: text, trimmed: trimmed)))
                }
            case .hashtag:
                if let _text = tweet.string(in: twitterTextEntity.range) {
                    let text = _text.hasPrefix("#") ? String(_text.dropFirst()) : _text
                    activeEntities.append(ActiveEntity(range: twitterTextEntity.range, type: .hashtag(text)))
                }
            case .screenName:
                if let _text = tweet.string(in: twitterTextEntity.range) {
                    let text = _text.hasPrefix("@") ? String(_text.dropFirst()) : _text
                    activeEntities.append(ActiveEntity(range: twitterTextEntity.range, type: .mention(text)))
                }
            default:
                continue
            }
        }
        
        var trimmedTweet = tweet
        for activeEntity in activeEntities {
            guard case .url = activeEntity.type else { continue }
            trimEntity(tweet: &trimmedTweet, activeEntity: activeEntity, activeEntities: activeEntities)
        }
        
        return TweetParseResult(
            originalTweet: tweet,
            trimmedTweet: trimmedTweet,
            activeEntities: activeEntities
        )
    }
    
    static func trimEntity(tweet: inout String, activeEntity: ActiveEntity, activeEntities:  [ActiveEntity]) {
        guard case let .url(original, trimmed) = activeEntity.type else { return }
        guard let index = activeEntities.firstIndex(where: { $0.range == activeEntity.range }) else { return }
        guard let range = Range(activeEntity.range, in: tweet) else { return }
        tweet.replaceSubrange(range, with: trimmed)
        
        let offset = trimmed.count - original.count
        activeEntity.range.length += offset
        
        let moveActiveEntities = Array(activeEntities[index...].dropFirst())
        for moveActiveEntity in moveActiveEntities {
            moveActiveEntity.range.location += offset
        }
    }
    
}

extension String {
    func string(in nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}
