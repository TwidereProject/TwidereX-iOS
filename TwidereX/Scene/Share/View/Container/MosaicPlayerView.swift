//
//  MosaicPlayerView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import AVKit

final class MosaicPlayerView: UIView {
    
    static let cornerRadius: CGFloat = 8

    private let container = UIView()
    private let touchBlockingView = TouchBlockingView()
    private var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    let playerViewController = AVPlayerViewController()
    
    let gifIndicatorBackgroundVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        visualEffectView.alpha = 0.9
        visualEffectView.layer.masksToBounds = true
        visualEffectView.layer.cornerRadius = 4
        visualEffectView.layer.cornerCurve = .continuous
        return visualEffectView
    }()
    let gifIndicatorBackgroundVibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))
    
    let gifIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.text = "GIF"
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MosaicPlayerView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            containerHeightLayoutConstraint
        ])
        
        gifIndicatorBackgroundVibrancyEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gifIndicatorBackgroundVisualEffectView.contentView.addSubview(gifIndicatorBackgroundVibrancyEffectView)
        
        gifIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        gifIndicatorBackgroundVibrancyEffectView.contentView.addSubview(gifIndicatorLabel)
        NSLayoutConstraint.activate([
            gifIndicatorLabel.topAnchor.constraint(equalTo: gifIndicatorBackgroundVibrancyEffectView.topAnchor, constant: 4),
            gifIndicatorLabel.leadingAnchor.constraint(equalTo: gifIndicatorBackgroundVibrancyEffectView.layoutMarginsGuide.leadingAnchor),
            gifIndicatorBackgroundVibrancyEffectView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: gifIndicatorLabel.trailingAnchor),
            gifIndicatorBackgroundVibrancyEffectView.bottomAnchor.constraint(equalTo: gifIndicatorLabel.bottomAnchor, constant: 4),
        ])
        
        // will not influence full-screen playback
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.layer.cornerRadius = MosaicPlayerView.cornerRadius
        playerViewController.view.layer.cornerCurve = .continuous
    }
}

extension MosaicPlayerView {

    func reset() {
        // note: set playerViewController.player pause() and nil in data source configuration process make reloadData not break playing
        
        gifIndicatorBackgroundVisualEffectView.removeFromSuperview()
        
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
        
        container.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
    
    func setupPlayer(aspectRatio: CGSize, maxSize: CGSize, parent: UIViewController?) -> AVPlayerViewController {
        reset()
        
        touchBlockingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(touchBlockingView)
        NSLayoutConstraint.activate([
            touchBlockingView.topAnchor.constraint(equalTo: container.topAnchor),
            touchBlockingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            touchBlockingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        let rect = AVMakeRect(
            aspectRatio: aspectRatio,
            insideRect: CGRect(origin: .zero, size: maxSize)
        )
        
        parent?.addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        touchBlockingView.addSubview(playerViewController.view)
        parent.flatMap { playerViewController.didMove(toParent: $0) }
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: touchBlockingView.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: touchBlockingView.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: touchBlockingView.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: touchBlockingView.bottomAnchor),
            touchBlockingView.widthAnchor.constraint(equalToConstant: floor(rect.width)).priority(.required - 1),
        ])
        containerHeightLayoutConstraint.constant = floor(rect.height)
        containerHeightLayoutConstraint.isActive = true
        
        gifIndicatorBackgroundVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        touchBlockingView.addSubview(gifIndicatorBackgroundVisualEffectView)
        NSLayoutConstraint.activate([
            touchBlockingView.trailingAnchor.constraint(equalTo: gifIndicatorBackgroundVisualEffectView.trailingAnchor, constant: 8),
            touchBlockingView.bottomAnchor.constraint(equalTo: gifIndicatorBackgroundVisualEffectView.bottomAnchor, constant: 8),
        ])
        
        return playerViewController
    }
    
}
