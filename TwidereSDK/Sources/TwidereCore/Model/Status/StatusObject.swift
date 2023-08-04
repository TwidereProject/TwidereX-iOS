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
    
    public var id: String {
        switch self {
        case .twitter(let object):
            return object.id
        case .mastodon(let object):
            return object.id
        }
    }
    
    public var plaintextContent: String {
        switch self {
        case .twitter(let status):
            return status.displayText
        case .mastodon(let status):
            do {
                let content = MastodonContent(content: status.content, emojis: status.emojisTransient.asDictionary)
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
            let status = status.repost ?? status
            return status.attachmentsTransient.map { .twitter($0) }
        case .mastodon(let status):
            return status.attachmentsTransient.map { .mastodon($0) }
        }
    }
}

extension StatusObject {
    public var histories: Set<History> {
        switch self {
        case .twitter(let status):
            return status.histories
        case .mastodon(let status):
            return status.histories
        }
    }
}
