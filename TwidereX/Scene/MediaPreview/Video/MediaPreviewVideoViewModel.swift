//
//  MediaPreviewVideoViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AVKit

final class MediaPreviewVideoViewModel {
    
    // input
    let context: AppContext
    let item: Item
    
    // output
    public private(set) var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    
    init(context: AppContext, item: Item) {
        self.context = context
        self.item = item
        // end init

        switch item {
        case .gif(let mediaContext):
            guard let assertURL = mediaContext.assetURL else { return }
            let playerItem = AVPlayerItem(url: assertURL)
            let _player = AVQueuePlayer(playerItem: playerItem)
            _player.isMuted = true
            self.player = _player
            if let templateItem = _player.items().first {
                let _playerLooper = AVPlayerLooper(player: _player, templateItem: templateItem)
                self.playerLooper = _playerLooper
            }
        default:
            break
        }
        
    }
    
}

extension MediaPreviewVideoViewModel {
    enum Item {
        case video(RemoteVideoContext)
        case gif(RemoteGIFContext)
        case audio(RemoteAudioContext)
    }
    
    struct RemoteVideoContext {
        let assetURL: URL?
        let previewURL: URL?
        // let thumbnail: UIImage?
    }
    
    struct RemoteGIFContext {
        let assetURL: URL?
        let previewURL: URL?
    }
    
    struct RemoteAudioContext {
        let assetURL: URL?
        let previewURL: URL?
    }
}
