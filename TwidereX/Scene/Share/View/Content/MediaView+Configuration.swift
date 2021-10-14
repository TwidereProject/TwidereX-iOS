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
    enum Configuration {
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
        
        struct ImageInfo {
            let aspectRadio: CGSize
            let assetURL: String?
        }
        
        struct VideoInfo {
            let aspectRadio: CGSize
            let assertURL: String?
            let previewURL: String?
            let durationMS: Int?
        }
    }
}

extension MediaView {
    static func configuration(twitterStatus status: TwitterStatus) -> AnyPublisher<[MediaView.Configuration], Never> {
        func videoInfo(from attachment: TwitterAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assertURL: attachment.assetURL,
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
}
