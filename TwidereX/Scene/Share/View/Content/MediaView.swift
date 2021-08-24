//
//  MediaView.swift
//  MediaView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class MediaView: UIView {
    
    static let cornerRadius: CGFloat = 8
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = MediaView.cornerRadius
        return imageView
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
        #if DEBUG
        backgroundColor = .gray
        #endif
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
    
    func prepareForReuse() {
        imageView.removeFromSuperview()
        imageView.removeConstraints(imageView.constraints)
        imageView.af.cancelImageRequest()
        imageView.image = nil
    }
}
