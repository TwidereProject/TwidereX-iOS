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
    let thumbnail: UIImage?
    
    // output
    let preview = CurrentValueSubject<UIImage?, Never>(nil)
    
    init(thumbnail: UIImage?) {
        self.thumbnail = thumbnail
    }
}
