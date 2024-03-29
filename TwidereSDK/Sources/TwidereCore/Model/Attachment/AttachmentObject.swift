//
//  AttachmentObject.swift
//  
//
//  Created by MainasuK on 2021-12-7.
//

import Foundation
import CoreGraphics
import CoreDataStack

public enum AttachmentObject {
    case twitter(TwitterAttachment)
    case mastodon(MastodonAttachment)
}

extension AttachmentObject {
    public enum Kind {
        case image
        case video
        case gif
        case audio
    }
    
    public var kind: Kind {
        switch self {
        case .twitter(let twitterAttachment):
            switch twitterAttachment.kind {
            case .photo:        return .image
            case .video:        return .video
            case .animatedGIF:  return .gif
            }
        case .mastodon(let mastodonAttachment):
            switch mastodonAttachment.kind {
            case .image:        return  .image
            case .video:        return .video
            case .gifv:         return .gif
            case .audio:        return .audio
            }
        }
    }
}

extension AttachmentObject {
    public var assetURL: URL? {
        switch self {
        case .twitter(let twitterAttachment):
            return twitterAttachment.assetURL.flatMap { URL(string: $0) }
        case .mastodon(let mastodonAttachment):
            return mastodonAttachment.assetURL.flatMap { URL(string: $0) }
        }
    }
    
    public var previewURL: URL? {
        switch self {
        case .twitter(let twitterAttachment):
            return twitterAttachment.previewURL.flatMap { URL(string: $0) }
        case .mastodon(let mastodonAttachment):
            return mastodonAttachment.previewURL.flatMap { URL(string: $0) }
        }
    }
    
    public var downloadURL: URL? {
        switch self {
        case .twitter(let twitterAttachment):
            return twitterAttachment.downloadURL.flatMap { URL(string: $0) }
        case .mastodon(let mastodonAttachment):
            return mastodonAttachment.assetURL.flatMap { URL(string: $0) }
        }
    }
}

extension AttachmentObject {
    public var size: CGSize {
        switch self {
        case .twitter(let attachment):
            return attachment.size
        case .mastodon(let attachment):
            return attachment.size
        }
    }

}
