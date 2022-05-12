//
//  PlayerService.swift
//  
//
//  Created by MainasuK on 2022-5-12.
//

import os.log
import AVKit
import UIKit

public final class PlayerService: NSObject {
    
    let logger = Logger(subsystem: "PlayerService", category: "Serivce")
    
    public override init() {
        super.init()
    }
    
}

// seealso: `MediaPreviewVideoViewModel.init`
// MARK: - AVPlayerViewControllerDelegate
extension PlayerService: AVPlayerViewControllerDelegate {
    
    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate { _ in
            // do nothing
        } completion: { context in
            if !context.isCancelled {
                try? AVAudioSession.sharedInstance().setCategory(.playback)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
    }
    
    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate { _ in
            
        } completion: { context in
            if !context.isCancelled {
                try? AVAudioSession.sharedInstance().setCategory(.ambient)  // set to ambient to allow mixed (needed for GIFV)
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
    }
    
}
