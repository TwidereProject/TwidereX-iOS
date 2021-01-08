//
//  Tweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreDataStack
import TwitterAPI
import Kanna

extension Tweet.Property {
    init(entity: Twitter.Entity.Tweet, networkDate: Date) {
        // extra text from HTML
        let source: String? = {
            guard let sourceHTML = entity.source, let html = try? HTML(html: sourceHTML, encoding: .utf8) else { return nil }
            return html.text
        }()

        self.init(
            id: entity.idStr,
            text: entity.fullText ?? entity.text ?? "",
            createdAt: entity.createdAt,
            conversationID: nil,
            replyToTweetID: entity.inReplyToStatusIDStr,
            inReplyToUserID: entity.inReplyToUserIDStr,
            lang: nil,
            possiblySensitive: false,
            source: source,
            networkDate: networkDate)
    }
    
    init(entity: Twitter.Entity.V2.Tweet, replyToTweetID: Twitter.Entity.V2.Tweet.ID?, networkDate: Date) {
        self.init(
            id: entity.id,
            text: entity.text,
            createdAt: entity.createdAt,
            conversationID: entity.conversationID,
            replyToTweetID: replyToTweetID,
            inReplyToUserID: entity.inReplyToUserID,
            lang: entity.lang,
            possiblySensitive: entity.possiblySensitive ?? false,
            source: entity.source,
            networkDate: networkDate
        )
    }
}

extension Tweet {
    
    var tweetURL: URL {
        return URL(string: "https://twitter.com/\(author.username)/status/\(id)")!
    }
    
    var activityItems: [Any] {
        var items: [Any] = []
        
        items.append(tweetURL)
        
        if !text.isEmpty {
            items.append(displayText)
        }
        
        return items
    }
}

extension Tweet {
    var displayText: String {
        var text = self.text
        for url in entities?.urls ?? [] {
            guard let shortURL = url.url, let displayURL = url.displayURL, let expandedURL = url.expandedURL else { continue }
            guard !displayURL.hasPrefix("pic.twitter.com") else {
                text = text.replacingOccurrences(of: shortURL, with: "")
                continue
            }

            if let quote = quote {
                let quoteID = quote.id
                guard !displayURL.hasPrefix("twitter.com"), !expandedURL.hasPrefix(quoteID) else {
                    text = text.replacingOccurrences(of: shortURL, with: "")
                    continue
                }
            }
            
            text = text.replacingOccurrences(of: shortURL, with: expandedURL)
        }
        return text
    }
}
