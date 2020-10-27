//
//  ComposeTweetMediaCollectionVIewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-27.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class ComposeTweetMediaCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let imageView = UIImageView()
    let overlayBlurVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    let uploadActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension ComposeTweetMediaCollectionViewCell {
    private func _init() {
        contentView.backgroundColor = .systemBackground
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        overlayBlurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayBlurVisualEffectView)
        NSLayoutConstraint.activate([
            overlayBlurVisualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayBlurVisualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayBlurVisualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayBlurVisualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        uploadActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        overlayBlurVisualEffectView.contentView.addSubview(uploadActivityIndicatorView)
        NSLayoutConstraint.activate([
            uploadActivityIndicatorView.centerXAnchor.constraint(equalTo: overlayBlurVisualEffectView.centerXAnchor),
            uploadActivityIndicatorView.centerYAnchor.constraint(equalTo: overlayBlurVisualEffectView.centerYAnchor),
        ])
        
        overlayBlurVisualEffectView.alpha = 0.5
        uploadActivityIndicatorView.color = .black
        uploadActivityIndicatorView.hidesWhenStopped = true
        uploadActivityIndicatorView.stopAnimating()
    }
}
