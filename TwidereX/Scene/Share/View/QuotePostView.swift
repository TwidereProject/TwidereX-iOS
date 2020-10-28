//
//  QuotePostView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import UIKit
import ActiveLabel

final class QuotePostView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let verifiedBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.image = Asset.ObjectTools.verifiedBadge.image.withRenderingMode(.alwaysOriginal)
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.textColor = Asset.Colors.hightLight.color
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.text = "1d"
        return label
    }()
    
    let activeTextLabel = ActiveLabel(style: .default)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension QuotePostView {
    
    func _init() {
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.borderWidth = 3 * UIView.separatorLineHeight(of: self)    // 3px
        layer.borderColor = UIColor.secondarySystemBackground.cgColor
        
        // container: [user avatar | tweet container]
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 10
        containerStackView.alignment = .top
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 8),
        ])
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.height).priority(.required - 1),
        ])
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            verifiedBadgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            verifiedBadgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        // tweet container: [user meta container | main container]
        let tweetContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .vertical
        tweetContainerStackView.spacing = 8
        
        let userMetaContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 4
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(lockImageView)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        userMetaContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // main container: [text]
        let mainContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(mainContainerStackView)
        mainContainerStackView.axis = .vertical
        mainContainerStackView.addArrangedSubview(activeTextLabel)
        
        lockImageView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        layer.borderColor = UIColor.secondarySystemBackground.cgColor
    }
    
}

#if DEBUG
import SwiftUI

struct QuotePostView_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var avatarImage2: UIImage {
        UIImage(named: "dan-maisey")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = QuotePostView()
                view.avatarImageView.image = avatarImage
                return view
            }
            .previewLayout(.fixed(width: 375, height: 300))
            .previewDisplayName("text")
            UIViewPreview(width: 375) {
                let view = QuotePostView()
                view.avatarImageView.image = avatarImage
                view.lockImageView.isHidden = false
                return view
            }
            .previewLayout(.fixed(width: 375, height: 300))
            .previewDisplayName("text + protected")
        }
    }
}
#endif
