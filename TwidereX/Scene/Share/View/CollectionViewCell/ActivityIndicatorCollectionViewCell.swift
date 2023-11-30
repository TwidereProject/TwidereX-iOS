//
//  ActivityIndicatorCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit 

final class ActivityIndicatorCollectionViewCell: UICollectionViewCell {
    
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ActivityIndicatorCollectionViewCell {
    
    private func _init() {
        backgroundColor = .clear
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            activityIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            activityIndicatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 16),
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
    }
    
}

