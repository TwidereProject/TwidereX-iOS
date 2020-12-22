//
//  NeedsDependency+AVPlayerViewControllerDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-18.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import AVKit

extension NeedsDependency where Self: AVPlayerViewControllerDelegate {
    
    func handlePlayerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        context.videoPlaybackService.playerViewModel(for: playerViewController)?.isFullScreenPresentationing = true
    }
    
    func handlePlayerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        context.videoPlaybackService.playerViewModel(for: playerViewController)?.isFullScreenPresentationing = false
    }

}
