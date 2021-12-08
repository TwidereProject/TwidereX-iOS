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
    
    deinit {
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
        
        playerViewController.view.backgroundColor = .clear
        playerViewController.player = viewModel.player
        
        switch viewModel.item {
        case .gif:
            playerViewController.showsPlaybackControls = false
            viewModel.player?.play()
        default:
            break
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
        guard let snapshot = playerView.snapshotView(afterScreenUpdates: true) else { return nil }
        
        return MediaPreviewTransitionContext(
            transitionView: playerView,
            snapshot: snapshot,
            snapshotTransitioning: snapshot
        )
    }
}
