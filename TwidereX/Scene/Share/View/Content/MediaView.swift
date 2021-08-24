//
//  MediaView.swift
//  MediaView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import AVKit
import UIKit

final class MediaView: UIView {
    
    static let cornerRadius: CGFloat = 8
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = MediaView.cornerRadius
        return imageView
    }()
    
    private(set) lazy var playerViewController: AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.layer.cornerCurve = .continuous
        playerViewController.view.layer.cornerRadius = MediaView.cornerRadius
        return playerViewController
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

extension MediaView {
    private func _init() {
        // lazy load later
    }
    
    func configure(imageURL: String?) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        let placeholder = UIImage.placeholder(color: .systemFill)
        guard let urlString = imageURL,
              let url = URL(string: urlString) else {
            imageView.image = placeholder
            return
        }
        imageView.af.setImage(
            withURL: url,
            placeholderImage: placeholder
        )
    }
    
    func configure(videoURL: String?, isGIF: Bool) {
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerViewController.view)
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        guard let urlString = videoURL,
              let url = URL(string: urlString)
        else { return }
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        playerViewController.player = player
    }
    
    func prepareForReuse() {
        // reset imageView
        imageView.removeFromSuperview()
        imageView.removeConstraints(imageView.constraints)
        imageView.af.cancelImageRequest()
        imageView.image = nil
        
        // reset playerViewController
        playerViewController.view.removeFromSuperview()
        playerViewController.player?.pause()
        playerViewController.player = nil
    }
}
