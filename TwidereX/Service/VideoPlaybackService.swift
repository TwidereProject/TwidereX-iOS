//
//  VideoPlaybackService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import AVKit
import Combine
import CoreDataStack

final class VideoPlaybackService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "com.twidere.twiderex.video-playback-service.working-queue")
    private(set) var viewPlayerViewModelDict: [URL: VideoPlayerViewModel] = [:]
    
    // only for video kind
    weak var latestPlayingVideoPlayerViewModel: VideoPlayerViewModel?
    
}

extension VideoPlaybackService {
    private func playerViewModel(_ playerViewModel: VideoPlayerViewModel, didUpdateTimeControlStatus: AVPlayer.TimeControlStatus) {
        switch playerViewModel.videoKind {
        case .gif:
            // do nothing
            return
        case .video:
            if playerViewModel.timeControlStatus.value != .paused {
                latestPlayingVideoPlayerViewModel = playerViewModel
                
                // pause other player
                for viewModel in viewPlayerViewModelDict.values {
                    guard viewModel.timeControlStatus.value != .paused else { continue }
                    guard viewModel !== playerViewModel else { continue }
                    viewModel.pause()
                }
            } else {
                if latestPlayingVideoPlayerViewModel === playerViewModel {
                    latestPlayingVideoPlayerViewModel = nil
                    try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
                    try? AVAudioSession.sharedInstance().setActive(false)
                }
            }
        }
    }
}

extension VideoPlaybackService {
    
    func dequeueVideoPlayerViewModel(for media: TwitterMedia) -> VideoPlayerViewModel? {
        // Core Data entity not thread-safe. Save attribute before enter working queue
        guard let height = media.height?.intValue,
              let width = media.width?.intValue,
              let url = media.url.flatMap({ URL(string: $0) }),
              media.type == "animated_gif" || media.type == "video" else
        { return nil }
        
        let previewImageURL = media.previewImageURL.flatMap({ URL(string: $0) })
        let videoKind: VideoPlayerViewModel.Kind = media.type == "animated_gif" ? .gif : .video
        
        var _viewModel: VideoPlayerViewModel?
        workingQueue.sync {
            if let viewModel = viewPlayerViewModelDict[url] {
                _viewModel = viewModel
            } else {
                let viewModel = VideoPlayerViewModel(
                    previewImageURL: previewImageURL,
                    videoURL: url,
                    videoSize: CGSize(width: width, height: height),
                    videoKind: videoKind
                )
                viewPlayerViewModelDict[url] = viewModel
                setupListener(for: viewModel)
                _viewModel = viewModel
            }
        }
        return _viewModel
    }
    
    func playerViewModel(for playerViewController: AVPlayerViewController) -> VideoPlayerViewModel? {
        guard let url = (playerViewController.player?.currentItem?.asset as? AVURLAsset)?.url else { return nil }
        return viewPlayerViewModelDict[url]
    }

    private func setupListener(for viewModel: VideoPlayerViewModel) {
        viewModel.timeControlStatus
            .sink { [weak self] timeControlStatus in
                guard let self = self else { return }
                self.playerViewModel(viewModel, didUpdateTimeControlStatus: timeControlStatus)
            }
            .store(in: &disposeBag)
    }
    
}

extension VideoPlaybackService {
    func markTransitioning(for tweet: Tweet) {
        guard let media = (tweet.retweet ?? tweet).media?.first else  { return }
        guard let viewModel = dequeueVideoPlayerViewModel(for: media) else  { return }
        viewModel.isTransitioning = true
    }
    
    func viewDidDisappear(from viewController: UIViewController?) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        // note: do not retain view controller
        // pause all player when view disppear exclude full screen player and other transitioning scene
        for viewModel in viewPlayerViewModelDict.values {
            guard !viewModel.isTransitioning else {
                viewModel.isTransitioning = false
                continue
            }
            guard !viewModel.isFullScreenPresentationing else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: isFullScreenPresentationing", ((#file as NSString).lastPathComponent), #line, #function)
                continue
            }
            guard viewModel.videoKind == .video else { continue }
            viewModel.pause()
        }
    }
}
