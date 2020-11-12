//
//  MosaicImageViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack

struct MosaicImageViewModel {
    
    let metas: [MosaicMeta]
    
    init(twitterMedia media: [TwitterMedia]) {
        var metas: [MosaicMeta] = []
        for element in media {
            guard let (url, size) = element.photoURL(sizeKind: .small) else { continue }
            let meta = MosaicMeta(url: url, size: size)
            metas.append(meta)
        }
        self.metas = metas
    }
    
}

struct MosaicMeta {
    let url: URL
    let size: CGSize
}
