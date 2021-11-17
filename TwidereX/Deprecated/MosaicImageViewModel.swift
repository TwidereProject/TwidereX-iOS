//
//  MosaicImageViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack

@available(*, deprecated, message: "")
struct MosaicImageViewModel {
    
    let metas: [MosaicMeta]
    
    init(twitterMedia media: [TwitterMedia]) {
        var metas: [MosaicMeta] = []
        let mediaSizeKind: TwitterMedia.SizeKind = UIDevice.current.userInterfaceIdiom == .phone ? .small : .medium
        for element in media where element.type == "photo" {
            guard let (url, size) = element.photoURL(sizeKind: mediaSizeKind) else { continue }
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
