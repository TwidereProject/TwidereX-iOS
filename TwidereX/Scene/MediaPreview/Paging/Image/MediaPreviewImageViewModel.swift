//
//  MediaPreviewImageViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-6.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

class MediaPreviewImageViewModel {
    
    // input
    let item: ImagePreviewItem
        
    init(meta: TweetImagePreviewMeta) {
        self.item = .tweet(meta)
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
    }
    
}

extension MediaPreviewImageViewModel {
    enum ImagePreviewItem {
        case tweet(TweetImagePreviewMeta)
        case local(LocalImagePreviewMeta)
    }
    
    struct TweetImagePreviewMeta {
        let url: URL
        let thumbnail: UIImage?
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
    
}
