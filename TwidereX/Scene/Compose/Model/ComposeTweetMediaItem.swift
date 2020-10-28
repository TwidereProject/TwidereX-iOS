//
//  ComposeTweetMediaItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-27.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation

enum ComposeTweetMediaItem {
    case media(mediaService: TwitterMediaService)
}

extension ComposeTweetMediaItem: Hashable { }
