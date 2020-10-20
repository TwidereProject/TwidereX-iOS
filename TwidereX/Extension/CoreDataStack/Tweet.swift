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
            text: entity.text,
            createdAt: entity.createdAt,
            conversationID: nil,
            inReplyToUserID: nil,
            lang: nil,
            possiblySensitive: false,
            source: source,
            networkDate: networkDate)
    }
}
