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
    let url: URL
    let thumbnail: UIImage?
    
    // output
    let preview = CurrentValueSubject<UIImage?, Never>(nil)
    
    init(url: URL, thumbnail: UIImage?) {
        self.url = url
        self.thumbnail = thumbnail
    }
}
