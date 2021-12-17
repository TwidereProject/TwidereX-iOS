//
//  CustomEmojiPickerItemCollectionViewCell.swift
//  
//
//  Created by MainasuK on 2021-11-28.
//


import UIKit
import SDWebImage

final class CustomEmojiPickerItemCollectionViewCell: UICollectionViewCell {
    
    static let itemSize = CGSize(width: 44, height: 44)
    
    static let placeholder = UIImage.placeholder(color: .systemFill)

    let emojiImageView: SDAnimatedImageView = {
        let imageView = SDAnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override var isHighlighted: Bool {
        didSet {
            emojiImageView.alpha = isHighlighted ? 0.5 : 1.0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CustomEmojiPickerItemCollectionViewCell {
    
    private func _init() {
        emojiImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiImageView)
        NSLayoutConstraint.activate([
            emojiImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            emojiImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7),
            contentView.trailingAnchor.constraint(equalTo: emojiImageView.trailingAnchor, constant: 7),
            contentView.bottomAnchor.constraint(equalTo: emojiImageView.bottomAnchor, constant: 7),
        ])
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "emoji"
    }
    
}
