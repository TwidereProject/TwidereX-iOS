//
//  ContextMenuImagePreviewViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class ContextMenuImagePreviewViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let aspectRatio: CGSize
    let thumbnail: UIImage?
    let url = CurrentValueSubject<URL?, Never>(nil)
    
    init(aspectRatio: CGSize, thumbnail: UIImage?) {
        self.aspectRatio = aspectRatio
        self.thumbnail = thumbnail
    }
    
}
