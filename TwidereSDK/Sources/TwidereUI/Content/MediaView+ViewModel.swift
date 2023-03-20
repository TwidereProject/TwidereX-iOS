//
//  MediaView+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import CoreData
import CoreDataStack
import Photos

extension MediaView {
    public class ViewModel: ObservableObject, Hashable {
        
        public static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.zeroFormattingBehavior = .pad
            formatter.allowedUnits = [.minute, .second]
            return formatter
        }()
        
        // input
        public let mediaKind: MediaKind
        public let aspectRatio: CGSize
        public let altText: String?
        
        public let previewURL: URL?
        public let assetURL: URL?
        public let downloadURL: URL?
        
        // video duration in MS
        public let durationMS: Int?
        
        @Published public var shouldHideForTransitioning = false
        
        // output
        public var durationText: String?
        public var thumbnail: UIImage? = nil
        public var frameInWindow: CGRect = .zero
        
        public init(
            mediaKind: MediaKind,
            aspectRatio: CGSize,
            altText: String?,
            previewURL: URL?,
            assetURL: URL?,
            downloadURL: URL?,
            durationMS: Int?
        ) {
            self.mediaKind = mediaKind
            self.aspectRatio = aspectRatio
            self.altText = altText
            self.previewURL = previewURL
            self.assetURL = assetURL
            self.downloadURL = downloadURL
            self.durationMS = durationMS
            // end init
    
            self.durationText = durationMS.flatMap { durationMS -> String? in
                let timeInterval = TimeInterval(durationMS / 1000)
                guard timeInterval > 0 else { return nil }
                guard let text = MediaView.ViewModel.durationFormatter.string(from: timeInterval) else { return nil }
                return text
            }
        }
        
        public static func == (lhs: MediaView.ViewModel, rhs: MediaView.ViewModel) -> Bool {
            return lhs.mediaKind == rhs.mediaKind
                && lhs.aspectRatio == rhs.aspectRatio
                && lhs.altText == rhs.altText
                && lhs.previewURL == rhs.previewURL
                && lhs.assetURL == rhs.assetURL
                && lhs.downloadURL == rhs.downloadURL
                && lhs.durationMS == rhs.durationMS
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(mediaKind)
            hasher.combine(aspectRatio.width)
            hasher.combine(aspectRatio.height)
            hasher.combine(altText)
            hasher.combine(previewURL)
            hasher.combine(assetURL)
            hasher.combine(downloadURL)
            hasher.combine(durationMS)
        }
        
    }
}

extension MediaView.ViewModel {
    public enum MediaKind {
        case video
        case photo
        case animatedGIF
    }
}


//extension MediaView {
//    public enum Configuration: Hashable {
//        case image(info: ImageInfo)
//        case gif(info: VideoInfo)
//        case video(info: VideoInfo)
//
//        public var aspectRadio: CGSize {
//            switch self {
//            case .image(let info):      return info.aspectRadio
//            case .gif(let info):        return info.aspectRadio
//            case .video(let info):      return info.aspectRadio
//            }
//        }
//
//        public var assetURL: String? {
//            switch self {
//            case .image(let info):
//                return info.assetURL
//            case .gif(let info):
//                return info.assetURL
//            case .video(let info):
//                return info.assetURL
//            }
//        }
//
//        public var downloadURL: String? {
//            switch self {
//            case .image(let info):
//                return info.downloadURL ?? info.assetURL
//            case .gif(let info):
//                return info.assetURL
//            case .video(let info):
//                return info.assetURL
//            }
//        }
//
//        public var resourceType: PHAssetResourceType {
//            switch self {
//            case .image:
//                return .photo
//            case .gif:
//                return .video
//            case .video:
//                return .video
//            }
//        }
//
//        public struct ImageInfo: Hashable {
//            public let aspectRadio: CGSize
//            public let assetURL: String?
//            public let downloadURL: String?
//
//            public init(
//                aspectRadio: CGSize,
//                assetURL: String?,
//                downloadURL: String?
//            ) {
//                self.aspectRadio = aspectRadio
//                self.assetURL = assetURL
//                self.downloadURL = downloadURL
//            }
//
//            public func hash(into hasher: inout Hasher) {
//                hasher.combine(aspectRadio.width)
//                hasher.combine(aspectRadio.height)
//                assetURL.flatMap { hasher.combine($0) }
//            }
//        }
//
//        public struct VideoInfo: Hashable {
//            public let aspectRadio: CGSize
//            public let assetURL: String?
//            public let previewURL: String?
//            public let durationMS: Int?
//
//            public init(
//                aspectRadio: CGSize,
//                assetURL: String?,
//                previewURL: String?,
//                durationMS: Int?
//            ) {
//                self.aspectRadio = aspectRadio
//                self.assetURL = assetURL
//                self.previewURL = previewURL
//                self.durationMS = durationMS
//            }
//
//            public func hash(into hasher: inout Hasher) {
//                hasher.combine(aspectRadio.width)
//                hasher.combine(aspectRadio.height)
//                assetURL.flatMap { hasher.combine($0) }
//                previewURL.flatMap { hasher.combine($0) }
//                durationMS.flatMap { hasher.combine($0) }
//            }
//        }
//    }
//}
//
extension MediaView.ViewModel {
    public static func viewModels(from status: TwitterStatus) -> [MediaView.ViewModel] {
        return status.attachments.map { attachment -> MediaView.ViewModel in
            MediaView.ViewModel(
                mediaKind: {
                    switch attachment.kind {
                    case .photo:        return .photo
                    case .video:        return .video
                    case .animatedGIF:  return .animatedGIF
                    }
                }(),
                aspectRatio: attachment.size,
                altText: attachment.altDescription,
                previewURL: (attachment.previewURL ?? attachment.assetURL).flatMap { URL(string: $0) },
                assetURL: attachment.assetURL.flatMap { URL(string: $0) },
                downloadURL: attachment.downloadURL.flatMap { URL(string: $0) },
                durationMS: attachment.durationMS
            )
        }
    }
    
    public static func viewModels(from status: MastodonStatus) -> [MediaView.ViewModel] {
        return status.attachments.map { attachment -> MediaView.ViewModel in
            MediaView.ViewModel(
                mediaKind: {
                    switch attachment.kind {
                    case .image:        return .photo
                    case .video:        return .video
                    case .audio:        return .video
                    case .gifv:         return .animatedGIF
                    }
                }(),
                aspectRatio: attachment.size,
                altText: attachment.altDescription,
                previewURL: (attachment.previewURL ?? attachment.assetURL).flatMap { URL(string: $0) },
                assetURL: attachment.assetURL.flatMap { URL(string: $0) },
                downloadURL: attachment.downloadURL.flatMap { URL(string: $0) },
                durationMS: attachment.durationMS
            )
        }
    }

//    public static func configuration(mastodonStatus status: MastodonStatus) -> [MediaView.Configuration] {
//        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
//            MediaView.Configuration.VideoInfo(
//                aspectRadio: attachment.size,
//                assetURL: attachment.assetURL,
//                previewURL: attachment.previewURL,
//                durationMS: attachment.durationMS
//            )
//        }
//
//        let status = status.repost ?? status
//        return status.attachments.map { attachment -> MediaView.Configuration in
//            switch attachment.kind {
//            case .image:
//                let info = MediaView.Configuration.ImageInfo(
//                    aspectRadio: attachment.size,
//                    assetURL: attachment.assetURL,
//                    downloadURL: attachment.downloadURL
//                )
//                return .image(info: info)
//            case .video:
//                let info = videoInfo(from: attachment)
//                return .video(info: info)
//            case .gifv:
//                let info = videoInfo(from: attachment)
//                return .gif(info: info)
//            case .audio:
//                // TODO:
//                let info = videoInfo(from: attachment)
//                return .video(info: info)
//            }
//        }
//    }
}
