//
//  TwitterStatus+Property.swift
//  TwitterStatus
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import CoreGraphics
import TwitterSDK

// MARK: - V1

extension TwitterStatus.Property {
    init(entity: Twitter.Entity.Tweet, networkDate: Date) {
        self.init(
            id: entity.id,
            text: entity.fullText ?? entity.text ?? "",
            likeCount: entity.favoriteCount ?? 0,
            replyCount: 0,
            repostCount: entity.retweetCount ?? 0,
            createdAt: entity.createdAt,
            updatedAt: networkDate,
            attachments: entity.twitterAttachments
        )
    }
}

extension Twitter.Entity.Tweet {
    var twitterAttachments: [TwitterAttachment] {
        guard let extendedEntities = self.extendedEntities,
              let media = extendedEntities.media
        else { return [] }
        
        let attachments = media.compactMap { media -> TwitterAttachment? in
            guard let kind = media.attachmentKind,
                  let size = media.sizes?.size(kind: .large),
                  let width = size.w,
                  let height = size.h
            else { return nil }
            return TwitterAttachment(
                kind: kind,
                size: CGSize(width: width, height: height),
                assetURL: media.attachmentAssetURL,
                previewURL: media.attachmentPreviewURL,
                durationMS: media.videoInfo?.durationMillis,
                altDescription: media.extAltText
            )
        }
        
        return attachments
    }
}

extension Twitter.Entity.ExtendedEntities.Media {
    var attachmentKind: TwitterAttachment.Kind? {
        guard let type = self.type else { return nil }
        switch type {
        case "photo":           return .photo
        case "video":           return .video
        case "animated_gif":    return .animatedGIF
        default:                return nil
        }
    }
    
    var attachmentAssetURL: String? {
        guard let kind = attachmentKind else { return nil }
        switch kind {
        case .photo:        return mediaURLHTTPS
        case .video:        return videoInfo?.variants?.max(by: { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) })?.url
        case .animatedGIF:  return videoInfo?.variants?.max(by: { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) })?.url
        }
    }
    
    public var  attachmentPreviewURL: String? {
        guard let kind = attachmentKind else { return nil }
        switch kind {
        case .photo:            return nil
        case .video:            return mediaURLHTTPS
        case .animatedGIF:      return mediaURLHTTPS
        }
    }
}


// MARK: - V2

extension TwitterStatus.Property {
    init(
        status: Twitter.Entity.V2.Tweet,
        author: Twitter.Entity.V2.User,
        place: Twitter.Entity.V2.Place?,        // TODO:
        media: [Twitter.Entity.V2.Media],
        networkDate: Date
    ) {
        let attachments: [TwitterAttachment] = media.compactMap {
            $0.twitterAttachment
        }
        self.init(
            id: status.id,
            text: status.text,
            likeCount: status.publicMetrics?.likeCount ?? 0,
            replyCount: status.publicMetrics?.replyCount ?? 0,
            repostCount: status.publicMetrics?.retweetCount ?? 0,
            createdAt: status.createdAt,
            updatedAt: networkDate,
            attachments: attachments
        )
    }
}

extension Twitter.Entity.V2.Tweet {
    var repliedToID: Twitter.Entity.V2.Tweet.ID? {
        for referencedTweet in referencedTweets ?? [] {
            switch referencedTweet.type {
            case .repliedTo:
                return referencedTweet.id
            case .quoted:
                continue
            case .retweeted:
                continue
            case .none:
                continue
            }
        }
        return nil
    }
    
    var quoteID: Twitter.Entity.V2.Tweet.ID? {
        for referencedTweet in referencedTweets ?? [] {
            switch referencedTweet.type {
            case .repliedTo:
                continue
            case .quoted:
                return referencedTweet.id
            case .retweeted:
                continue
            case .none:
                continue
            }
        }
        return nil
    }
    
    var repostID: Twitter.Entity.V2.Tweet.ID? {
        for referencedTweet in referencedTweets ?? [] {
            switch referencedTweet.type {
            case .repliedTo:
                continue
            case .quoted:
                continue
            case .retweeted:
                return referencedTweet.id
            case .none:
                continue
            }
        }
        return nil
    }
}

extension Twitter.Entity.V2.Media {
    var twitterAttachment: TwitterAttachment? {
        guard let kind = attachmentKind else { return nil }
        guard let width = width,
            let height = height
        else { return nil }
        return TwitterAttachment(
            kind: kind,
            size: CGSize(width: width, height: height),
            assetURL: url,
            previewURL: previewImageURL,
            durationMS: durationMS,
            altDescription: nil
        )
    }
    
    var attachmentKind: TwitterAttachment.Kind? {
        switch type {
        case "photo":           return .photo
        case "video":           return .video
        case "animated_gif":    return .animatedGIF
        default:                return nil
        }
    }
}
