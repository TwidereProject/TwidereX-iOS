//
//  TwitterStatus.swift
//  
//
//  Created by MainasuK on 2021-12-7.
//

import Foundation
import CoreDataStack
import TwitterMeta

extension TwitterStatus {
    public var statusURL: URL {
        return URL(string: "https://twitter.com/\(author.username)/status/\(id)")!
    }
    
    public var displayText: String {
        var text = self.text
        for url in entities?.urls ?? [] {
            let shortURL = url.url
            guard let displayURL = url.displayURL,
                  let expandedURL = url.expandedURL
            else { continue }
            
            // drop media URL
            guard !displayURL.hasPrefix("pic.twitter.com") else {
                text = text.replacingOccurrences(of: shortURL, with: "")
                continue
            }

            // drop quote URL
            if let quote = quote {
                let quoteID = quote.id
                guard !displayURL.hasPrefix("twitter.com"),
                      !expandedURL.hasPrefix(quoteID)
                else {
                    text = text.replacingOccurrences(of: shortURL, with: "")
                    continue
                }
            }
            
            text = text.replacingOccurrences(of: shortURL, with: expandedURL)
        }
        return text
    }
    
    public var urlEntities: [TwitterContent.URLEntity] {
        let results = entities?.urls?.map { entity in
            TwitterContent.URLEntity(url: entity.url, expandedURL: entity.expandedURL, displayURL: entity.displayURL)
        }
        return results ?? []
    }
}

extension TwitterStatus {
    /// The tweet more then 240 characters
    public var hasMore: Bool {
        for url in entities?.urls ?? [] {
            guard text.localizedCaseInsensitiveContains("… " + url.url) else { continue }
            guard let expandedURL = url.expandedURL else { continue }
            guard expandedURL.hasPrefix("https://twitter.com/") else { continue }
            guard expandedURL.localizedCaseInsensitiveContains("status") else { continue }
            guard expandedURL.hasSuffix(self.id) else { continue }
            return true
        }
        
        return false
    }
}
