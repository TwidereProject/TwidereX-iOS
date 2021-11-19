//
//  ComposeAttachmentCollectionViewCell.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import UIKit
import Combine

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
    
    public private(set) lazy var optionImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ellipsis.circle.fill", in: .module, with: nil))
        return imageView
    }()
    
    let altImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "alt.rectangle", in: .module, with: nil))
        return imageView
    }()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        altImageView.isHidden = true
        imageView.image = nil
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

        optionImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(optionImageView)
        NSLayoutConstraint.activate([
            containerView.trailingAnchor.constraint(equalTo: optionImageView.trailingAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: optionImageView.bottomAnchor, constant: 4),
            optionImageView.widthAnchor.constraint(equalToConstant: 12).priority(.required - 1),
            optionImageView.heightAnchor.constraint(equalToConstant: 12).priority(.required - 1),
        ])
        
        altImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(altImageView)
        NSLayoutConstraint.activate([
            altImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: altImageView.bottomAnchor, constant: 4),
            altImageView.widthAnchor.constraint(equalToConstant: 16).priority(.required - 1),
            altImageView.heightAnchor.constraint(equalToConstant: 12).priority(.required - 1),
        ])
        
        altImageView.isHidden = true
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
        altImageView.isHidden = false
    }
    
}
