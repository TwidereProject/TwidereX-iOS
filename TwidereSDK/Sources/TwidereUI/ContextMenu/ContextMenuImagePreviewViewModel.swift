//
//  ContextMenuImagePreviewViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final public class ContextMenuImagePreviewViewModel {
    
    public var disposeBag = Set<AnyCancellable>()
    
    // input
    public let aspectRatio: CGSize
    public let thumbnail: UIImage?
    public let url = CurrentValueSubject<URL?, Never>(nil)
    
    public init(aspectRatio: CGSize, thumbnail: UIImage?) {
        self.aspectRatio = aspectRatio
        self.thumbnail = thumbnail
    }
    
}
