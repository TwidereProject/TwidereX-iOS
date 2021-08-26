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
            attachments: entity.attachments
        )
    }
}

extension Twitter.Entity.Tweet {
    var attachments: [TwitterAttachment] {
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
                durationMS: media.videoInfo?.durationMillis
            )
        }
        
        return attachments
    }
    
    var attachmentsRaw: Data? {
        guard let extendedEntities = self.extendedEntities,
              let media = extendedEntities.media
        else { return nil }
        
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
                durationMS: media.videoInfo?.durationMillis
            )
        }
        
        do {
            return try JSONEncoder().encode(attachments)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
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
