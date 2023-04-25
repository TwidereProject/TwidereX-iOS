//
//  GIFVideoPlayerRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/28.
//

import os.log
import UIKit
import SwiftUI
import Combine
import AVKit
import AVFoundation

public struct GIFVideoPlayerRepresentable: UIViewRepresentable {
    
    let controller = AVPlayerViewController()
    
    // input
    let assetURL: URL
    
    // output
    
    public func makeUIView(context: Context) -> UIView {
        let playerItem = AVPlayerItem(url: assetURL)
        let player = AVQueuePlayer(playerItem: playerItem)
        player.isMuted = true
        context.coordinator.player = player
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        context.coordinator.playerLooper = playerLooper
        
        controller.player = player
        controller.showsPlaybackControls = false
        
        controller.view.alpha = 0
        context.coordinator.setupPlayer()
        
        return controller.view
    }
    
    public func updateUIView(_ view: UIView, context: Context) {
        // do nothing
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator {
        var disposeBag = Set<AnyCancellable>()
        
        let representable: GIFVideoPlayerRepresentable
        
        var player: AVPlayer?
        var playerLooper: AVPlayerLooper?
        
        init(_ representable: GIFVideoPlayerRepresentable) {
            self.representable = representable
        }
        
        func setupPlayer() {
            guard let player = self.player,
                  let playerItem = player.currentItem
            else {
                assertionFailure()
                return
            }
            
            playerItem.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self = self else { return }
                    switch status {
                    case .readyToPlay:
                        self.representable.controller.view.alpha = 1
                        self.player?.play()
                    default:
                        break
                    }
                }
                .store(in: &disposeBag)
        }   // end func
        
        deinit {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
            disposeBag.removeAll()
            
            player?.pause()
            player = nil
            playerLooper?.disableLooping()
            playerLooper = nil
            representable.controller.player = nil
            representable.controller.removeFromParent()
            representable.controller.view.removeFromSuperview()
        }
    }   // end Coordinator
    
}
