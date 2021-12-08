//
//  StatusObject.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonMeta

public enum StatusObject: Hashable {
    case twitter(object: TwitterStatus)
    case mastodon(object: MastodonStatus)
}

extension StatusObject {
    public var asRecord: StatusRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            return .mastodon(record: .init(objectID: object.objectID))
        }
    }
}

extension StatusObject {
    
    public var plaintextContent: String {
        switch self {
        case .twitter(let status):
            return status.displayText
        case .mastodon(let status):
            do {
                let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent.original
            } catch {
                return status.content
            }
        }
    }
    
    public var statusURL: URL? {
        switch self {
        case .twitter(let status):
            return status.statusURL
        case .mastodon(let status):
            return URL(string: status.url ?? status.uri)
        }
    }
    
    public var attachments: [AttachmentObject] {
        switch self {
        case .twitter(let status):
            return status.attachments.map { .twitter($0) }
        case .mastodon(let status):
            return status.attachments.map { .mastodon($0) }
        }
    }
}
