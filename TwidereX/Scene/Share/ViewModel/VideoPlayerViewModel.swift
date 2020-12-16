//
//  VideoPlayerViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack

struct VideoPlayerViewModel {
    
    let meta: VideoPlayerMeta
    
    init?(twitterMedia media: TwitterMedia) {
        guard let height = media.height?.intValue,
              let width = media.width?.intValue,
              let previewImageURL = media.previewImageURL.flatMap({ URL(string: $0) }),
              let url = media.url.flatMap({ URL(string: $0) }),
              media.type == "animated_gif" || media.type == "video" else
        { return nil }
              
        meta = VideoPlayerMeta(
            previewImageURL: previewImageURL,
            url: url,
            size: CGSize(width: width, height: height),
            kind: media.type == "animated_gif" ? .gif : .video
        )
    }
    
}

struct VideoPlayerMeta {
    let previewImageURL: URL
    let url: URL
    let size: CGSize
    let kind: Kind
    
    enum Kind {
        case gif
        case video
    }
}
