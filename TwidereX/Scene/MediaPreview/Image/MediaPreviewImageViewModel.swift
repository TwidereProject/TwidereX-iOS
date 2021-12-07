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
    let context: AppContext
    let item: Item
        
    init(context: AppContext, item: Item) {
        self.context = context
        self.item = item
    }
        
}

extension MediaPreviewImageViewModel {
    enum Item {
        case remote(RemoteImageContext)
        case local(LocalImageContext)
    }
    
    struct RemoteImageContext {
        let assetURL: URL?
        let thumbnail: UIImage?
    }
    
    struct LocalImageContext {
        let image: UIImage
    }
    
}
