//
//  MediaView+Configuration.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import Photos

extension MediaView {
    public enum Configuration: Hashable {
        case image(info: ImageInfo)
        case gif(info: VideoInfo)
        case video(info: VideoInfo)
        
        public var aspectRadio: CGSize {
            switch self {
            case .image(let info):      return info.aspectRadio
            case .gif(let info):        return info.aspectRadio
            case .video(let info):      return info.aspectRadio
            }
        }
        
        public var assetURL: String? {
            switch self {
            case .image(let info):
                return info.assetURL
            case .gif(let info):
                return info.assetURL
            case .video(let info):
                return info.assetURL
            }
        }
        
        public var downloadURL: String? {
            switch self {
            case .image(let info):
                return info.downloadURL ?? info.assetURL
            case .gif(let info):
                return info.assetURL
            case .video(let info):
                return info.assetURL
            }
        }
        
        public var resourceType: PHAssetResourceType {
            switch self {
            case .image:
                return .photo
            case .gif:
                return .video
            case .video:
                return .video
            }
        }
        
        public struct ImageInfo: Hashable {
            public let aspectRadio: CGSize
            public let assetURL: String?
            public let downloadURL: String?
            
            public init(
                aspectRadio: CGSize,
                assetURL: String?,
                downloadURL: String?
            ) {
                self.aspectRadio = aspectRadio
                self.assetURL = assetURL
                self.downloadURL = downloadURL
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(aspectRadio.width)
                hasher.combine(aspectRadio.height)
                assetURL.flatMap { hasher.combine($0) }
            }
        }
        
        public struct VideoInfo: Hashable {
            public let aspectRadio: CGSize
            public let assetURL: String?
            public let previewURL: String?
            public let durationMS: Int?
            
            public init(
                aspectRadio: CGSize,
                assetURL: String?,
                previewURL: String?,
                durationMS: Int?
            ) {
                self.aspectRadio = aspectRadio
                self.assetURL = assetURL
                self.previewURL = previewURL
                self.durationMS = durationMS
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(aspectRadio.width)
                hasher.combine(aspectRadio.height)
                assetURL.flatMap { hasher.combine($0) }
                previewURL.flatMap { hasher.combine($0) }
                durationMS.flatMap { hasher.combine($0) }
            }
        }
    }
}

extension MediaView {
    public static func configuration(twitterStatus status: TwitterStatus) -> [MediaView.Configuration] {
        func videoInfo(from attachment: TwitterAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        return status.attachments.map { attachment -> MediaView.Configuration in
            switch attachment.kind {
            case .photo:
                let info = MediaView.Configuration.ImageInfo(
                    aspectRadio: attachment.size,
                    assetURL: attachment.assetURL,
                    downloadURL: attachment.downloadURL
                )
                return .image(info: info)
            case .video:
                let info = videoInfo(from: attachment)
                return .video(info: info)
            case .animatedGIF:
                let info = videoInfo(from: attachment)
                return .gif(info: info)
            }
        }
    }
    
    public static func configuration(mastodonStatus status: MastodonStatus) -> [MediaView.Configuration] {
        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        return status.attachments.map { attachment -> MediaView.Configuration in
            switch attachment.kind {
            case .image:
                let info = MediaView.Configuration.ImageInfo(
                    aspectRadio: attachment.size,
                    assetURL: attachment.assetURL,
                    downloadURL: attachment.downloadURL
                )
                return .image(info: info)
            case .video:
                let info = videoInfo(from: attachment)
                return .video(info: info)
            case .gifv:
                let info = videoInfo(from: attachment)
                return .gif(info: info)
            case .audio:
                // TODO:
                let info = videoInfo(from: attachment)
                return .video(info: info)
            }
        }
    }
}
