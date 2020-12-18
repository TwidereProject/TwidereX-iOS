//
//  VideoPlayerViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AVKit
import CoreDataStack
import Combine

final class VideoPlayerViewModel {

    // input
    let previewImageURL: URL?
    let videoURL: URL
    let videoSize: CGSize
    let videoKind: Kind
    
    let playerViewControllers = NSHashTable<AVPlayerViewController>.weakObjects()
    var isFullScreenPresentationing = false
    var isPlayingWhenEndDisplaying = false
    var updateDate = Date()
    
    // output
    let player: AVPlayer
    private(set) var looper: AVPlayerLooper?     // works with AVQueuePlayer (iOS 10+)
    
    private var timeControlStatusObservation: NSKeyValueObservation?
    let timeControlStatus = CurrentValueSubject<AVPlayer.TimeControlStatus, Never>(.paused)
    
    init(previewImageURL: URL?, videoURL: URL, videoSize: CGSize, videoKind: VideoPlayerViewModel.Kind) {
        self.previewImageURL = previewImageURL
        self.videoURL = videoURL
        self.videoSize = videoSize
        self.videoKind = videoKind
        
        let playerItem = AVPlayerItem(url: videoURL)
        let player = videoKind == .gif ? AVQueuePlayer(playerItem: playerItem) : AVPlayer(playerItem: playerItem)
        player.isMuted = true
        self.player = player
        
        if videoKind == .gif {
            setupLooper()
        }
        
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: player state: %s", ((#file as NSString).lastPathComponent), #line, #function, player.timeControlStatus.debugDescription)
            self.timeControlStatus.value = player.timeControlStatus
        }
    }
    
    deinit {
        timeControlStatusObservation = nil
    }
    
}

extension VideoPlayerViewModel {
    enum Kind {
        case gif
        case video
    }
}

extension VideoPlayerViewModel {
    
    func setupLooper() {
        guard looper == nil, let queuePlayer = player as? AVQueuePlayer else { return }
        guard let templateItem = queuePlayer.items().first else { return }
        looper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
    }
    
    func play() {
        player.play()
        updateDate = Date()
    }
    
    func pause() {
        player.pause()
        updateDate = Date()
    }
    
    func willDisplay(with playerViewController: AVPlayerViewController) {
        playerViewControllers.add(playerViewController)
        
        switch videoKind {
        case .gif:
            player.play()   // always auto play GIF
        case .video:
            guard isPlayingWhenEndDisplaying else { return }
            // mute before resume 
            player.isMuted = true
            player.play()
        }
        
        updateDate = Date()
    }
    
    func didEndDisplaying(with playerViewController: AVPlayerViewController) {
        playerViewControllers.remove(playerViewController)
        isPlayingWhenEndDisplaying = timeControlStatus.value != .paused
        player.pause()
        
        updateDate = Date()
    }
    
}
