//
//  ComposeAttachmentCollectionViewCell.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import UIKit
import Combine
import TwidereAsset

final public class ComposeAttachmentCollectionViewCell: UICollectionViewCell {
    
    static let dimension: CGFloat = 56
    static let imageViewSize = CGSize(width: dimension, height: dimension)
    
    static let placeholderColor = UIColor.systemGray6
    
    var disposeBag = Set<AnyCancellable>()
    
    public let containerView = UIView()     // use dedicate container view to coordinate with collectionView context menu preview controller
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        return activityIndicatorView
    }()
    
    public private(set) lazy var optionImageView: UIImageView = {
        let image = Asset.Editing.ellipsisCircleFill.image
        let imageView = UIImageView(image: image)
        return imageView
    }()
    
    let indicatorImageView: UIImageView = {
        let image = Asset.Media.altRectangle.image
        let imageView = UIImageView(image: image)
        return imageView
    }()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        indicatorImageView.isHidden = true
        imageView.image = nil
        activityIndicatorView.stopAnimating()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeAttachmentCollectionViewCell {
    
    private func _init() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        optionImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(optionImageView)
        NSLayoutConstraint.activate([
            containerView.trailingAnchor.constraint(equalTo: optionImageView.trailingAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: optionImageView.bottomAnchor, constant: 4),
            optionImageView.widthAnchor.constraint(equalToConstant: 16).priority(.required - 1),
            optionImageView.heightAnchor.constraint(equalToConstant: 16).priority(.required - 1),
        ])
        
        indicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(indicatorImageView)
        NSLayoutConstraint.activate([
            indicatorImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            indicatorImageView.centerYAnchor.constraint(equalTo: optionImageView.centerYAnchor),
            indicatorImageView.widthAnchor.constraint(equalToConstant: 16).priority(.required - 1),
            indicatorImageView.heightAnchor.constraint(equalToConstant: 12).priority(.required - 1),
        ])
        
        indicatorImageView.isHidden = true
        containerView.backgroundColor = ComposeAttachmentCollectionViewCell.placeholderColor
        containerView.layer.masksToBounds = true
        containerView.layer.cornerCurve = .continuous
        containerView.layer.cornerRadius = 8
        containerView.layer.borderColor = ComposeAttachmentCollectionViewCell.placeholderColor.cgColor
        containerView.layer.borderWidth = 1
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            containerView.layer.borderColor = ComposeAttachmentCollectionViewCell.placeholderColor.cgColor
        }
    }
    
    public func setAltBadgeDisplay() {
        indicatorImageView.image = Asset.Media.altRectangle.image
        indicatorImageView.isHidden = false
    }
    
    public func setGIFBadgeDisplay() {
        indicatorImageView.image = Asset.Media.gifRectangle.image
        indicatorImageView.isHidden = false
    }
    
    public func setPlayerBadgeDisplay() {
        indicatorImageView.image = Asset.Media.playerRectangle.image
        indicatorImageView.isHidden = false
    }
    
}
