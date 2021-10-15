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

extension MediaView {
    enum Configuration: Hashable {
        case image(info: ImageInfo)
        case gif(info: VideoInfo)
        case video(info: VideoInfo)
        
        var aspectRadio: CGSize {
            switch self {
            case .image(let info):      return info.aspectRadio
            case .gif(let info):        return info.aspectRadio
            case .video(let info):      return info.aspectRadio
            }
        }
        
        struct ImageInfo: Hashable {
            let aspectRadio: CGSize
            let assetURL: String?
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(aspectRadio.width)
                hasher.combine(aspectRadio.height)
                assetURL.flatMap { hasher.combine($0) }
            }
        }
        
        struct VideoInfo: Hashable {
            let aspectRadio: CGSize
            let assetURL: String?
            let previewURL: String?
            let durationMS: Int?
            
            func hash(into hasher: inout Hasher) {
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
    static func configuration(twitterStatus status: TwitterStatus) -> AnyPublisher<[MediaView.Configuration], Never> {
        func videoInfo(from attachment: TwitterAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        return status.publisher(for: \.attachments)
            .map { attachments -> [MediaView.Configuration] in
                return attachments.map { attachment -> MediaView.Configuration in
                    switch attachment.kind {
                    case .photo:
                        let info = MediaView.Configuration.ImageInfo(
                            aspectRadio: attachment.size,
                            assetURL: attachment.assetURL
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
            .eraseToAnyPublisher()
    }
    
    static func configuration(mastodonStatus status: MastodonStatus) -> AnyPublisher<[MediaView.Configuration], Never> {
        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        return status.publisher(for: \.attachments)
            .map { attachments -> [MediaView.Configuration] in
                return attachments.map { attachment -> MediaView.Configuration in
                    switch attachment.kind {
                    case .image:
                        let info = MediaView.Configuration.ImageInfo(
                            aspectRadio: attachment.size,
                            assetURL: attachment.assetURL
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
            .eraseToAnyPublisher()
    }
}
