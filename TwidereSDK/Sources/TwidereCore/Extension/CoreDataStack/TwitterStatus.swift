//
//  TwitterStatus.swift
//  
//
//  Created by MainasuK on 2021-12-7.
//

import Foundation
import CoreDataStack

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
            
            guard !displayURL.hasPrefix("pic.twitter.com") else {
                text = text.replacingOccurrences(of: shortURL, with: "")
                continue
            }

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
}
