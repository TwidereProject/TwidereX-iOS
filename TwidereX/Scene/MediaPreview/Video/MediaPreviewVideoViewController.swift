//
//  MediaPreviewVideoViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import AVKit
import Combine

final class MediaPreviewVideoViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewVideoViewModel!
    
    // weak var delegate: MediaPreviewImageViewControllerDelegate?

//    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
//    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    let playerViewController = AVPlayerViewController()
    let previewImageView = UIImageView()

    deinit {
        playerViewController.player?.pause()
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MediaPreviewVideoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        NSLayoutConstraint.activate([
            playerViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
        playerViewController.didMove(toParent: self)
        
        if let contentOverlayView = playerViewController.contentOverlayView {
            previewImageView.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(previewImageView)
            NSLayoutConstraint.activate([
                previewImageView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
                previewImageView.leadingAnchor.constraint(equalTo: contentOverlayView.leadingAnchor),
                previewImageView.trailingAnchor.constraint(equalTo: contentOverlayView.trailingAnchor),
                previewImageView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor),
            ])
        }
        
        playerViewController.view.backgroundColor = .clear
        playerViewController.player = viewModel.player
        playerViewController.delegate = self
        
        switch viewModel.item {
        case .gif:
            playerViewController.showsPlaybackControls = false
        default:
            break
        }
        
        viewModel.player?.play()
        viewModel.playbackState = .playing
        
        if let previewURL = viewModel.item.previewURL {
            previewImageView.contentMode = .scaleAspectFit
            previewImageView.af.setImage(
                withURL: previewURL,
                placeholderImage: .placeholder(color: .systemFill)
            )
            
            playerViewController.publisher(for: \.isReadyForDisplay)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isReadyForDisplay in
                    guard let self = self else { return }
                    self.previewImageView.isHidden = isReadyForDisplay
                }
                .store(in: &disposeBag)
        }
    }
    
}

// MARK: - ShareActivityProvider
extension MediaPreviewVideoViewController: ShareActivityProvider {
    var activities: [Any] {
        return []
    }
    
    var applicationActivities: [UIActivity] {
        switch viewModel.item {
        case .gif(let mediaContext):
            guard let url = mediaContext.assetURL else { return [] }
            return [
                SavePhotoActivity(context: viewModel.context, url: url, resourceType: .video)
            ]
        default:
            return []
        }
    }
}

// MARK: - MediaPreviewTransitionViewController
extension MediaPreviewVideoViewController: MediaPreviewTransitionViewController {
    var mediaPreviewTransitionContext: MediaPreviewTransitionContext? {
        guard let playerView = playerViewController.view else { return nil }
        let _currentFrame: UIImage? = {
            guard let player = playerViewController.player else { return nil }
            guard let asset = player.currentItem?.asset else { return nil }
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.appliesPreferredTrackTransform = true   // fix orientation
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: player.currentTime(), actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                return image
            } catch {
                return previewImageView.image
            }
        }()
        let _snapshot: UIView? = {
            guard let currentFrame = _currentFrame else { return nil }
            let size = AVMakeRect(aspectRatio: currentFrame.size, insideRect: view.frame).size
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: size))
            imageView.image = currentFrame
            return imageView
        }()
        guard let snapshot = _snapshot else {
            return nil
        }
        
        return MediaPreviewTransitionContext(
            transitionView: playerView,
            snapshot: snapshot,
            snapshotTransitioning: snapshot
        )
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension MediaPreviewVideoViewController: AVPlayerViewControllerDelegate { }
