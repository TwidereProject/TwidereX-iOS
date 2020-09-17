//
//  TimelinePostView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import UIKit
import ActiveLabel

final class TimelinePostView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    let retweetContainerStackView = UIStackView()
    
    let retweetIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Arrows.mdiTwitterRetweet.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let retweetInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Bob Retweeted"
        return label
    }()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.lockCircle.image
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
    
    let moreMenuButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
        return button
    }()
    
    let mainContainerStackView = UIStackView()
    let activeTextLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.enabledTypes = [.mention, .hashtag, .url]
        label.textColor = .label
        label.font = .systemFont(ofSize: 14)
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        return label
    }()
    let mosaicImageView = MosaicImageView()
    let quotePostView = QuotePostView()
    
    let actionToolbar = TimelinePostActionToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension TimelinePostView {
    
    func _init() {
        backgroundColor = .systemBackground
        
        // container: [retweet | post]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 2
        //containerStackView.alignment = .top
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // retweet container: [retweet icon | tweet info]
        containerStackView.addArrangedSubview(retweetContainerStackView)
        retweetContainerStackView.axis = .horizontal
        
        let retweetContainerContentView = UIView()
        retweetContainerStackView.addArrangedSubview(retweetContainerContentView)
        
        retweetInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        retweetContainerContentView.addSubview(retweetInfoLabel)
        NSLayoutConstraint.activate([
            retweetInfoLabel.topAnchor.constraint(equalTo: retweetContainerContentView.topAnchor),
            retweetContainerContentView.trailingAnchor.constraint(equalTo: retweetInfoLabel.trailingAnchor),
            retweetContainerContentView.bottomAnchor.constraint(equalTo: retweetInfoLabel.bottomAnchor),
        ])
        retweetInfoLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        retweetIconImageView.translatesAutoresizingMaskIntoConstraints = false
        retweetContainerContentView.addSubview(retweetIconImageView)
        NSLayoutConstraint.activate([
            retweetIconImageView.centerYAnchor.constraint(equalTo: retweetInfoLabel.centerYAnchor),
            retweetIconImageView.widthAnchor.constraint(equalToConstant: 12),
            retweetIconImageView.heightAnchor.constraint(equalToConstant: 12).priority(.defaultHigh),
        ])
        
        // post container: [user avatar | tweet container]
        let postContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(postContainerStackView)
        postContainerStackView.axis = .horizontal
        postContainerStackView.spacing = 10
        postContainerStackView.alignment = .top
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        postContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.height).priority(.required - 1),
        ])
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 2),
            lockImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 2),
        ])

        // tweet container: [user meta container | main container | action toolbar]
        let tweetContainerStackView = UIStackView()
        postContainerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .vertical
        tweetContainerStackView.spacing = 2
        
        // user meta container: [name | username | date | menu]
        let userMetaContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        userMetaContainerStackView.addArrangedSubview(dateLabel)
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        userMetaContainerStackView.addArrangedSubview(moreMenuButton)
        NSLayoutConstraint.activate([
            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
            moreMenuButton.heightAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // align retweet label leading to name
        // align retweet icon trailing to avatar
        NSLayoutConstraint.activate([
            retweetInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            retweetIconImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        ])
        
        // main container: [text | image | quote]
        tweetContainerStackView.addArrangedSubview(mainContainerStackView)
        mainContainerStackView.axis = .vertical
        mainContainerStackView.spacing = 8
        activeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(activeTextLabel)
        mosaicImageView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(mosaicImageView)
        mainContainerStackView.addArrangedSubview(quotePostView)
        activeTextLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // action toolbar
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        tweetContainerStackView.addArrangedSubview(actionToolbar)
        actionToolbar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        lockImageView.isHidden = true
        retweetContainerStackView.isHidden = true
        mosaicImageView.isHidden = true
        quotePostView.isHidden = true
    }
    
}

#if DEBUG
import SwiftUI

struct TimelinePostView_Previews: PreviewProvider {
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
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text")
            UIViewPreview(width: 375) {
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text")
            UIViewPreview(width: 375) {
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                view.retweetContainerStackView.isHidden = false
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text + retweet")
            UIViewPreview(width: 375) {
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                view.lockImageView.isHidden = false
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text + protect")
            UIViewPreview(width: 375) {
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                view.quotePostView.avatarImageView.image = avatarImage2
                view.quotePostView.nameLabel.text = "Bob"
                view.quotePostView.usernameLabel.text = "@bob"
                view.quotePostView.isHidden = false
                return view
            }
            .previewLayout(.fixed(width: 375, height: 300))
            .previewDisplayName("text + quote")
            UIViewPreview(width: 375) {
                let view = TimelinePostView()
                view.avatarImageView.image = avatarImage
                let images = MosaicImageView_Previews.images.prefix(3)
                let imageViews = view.mosaicImageView.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                view.mosaicImageView.isHidden = false
                view.quotePostView.avatarImageView.image = avatarImage2
                view.quotePostView.nameLabel.text = "Bob"
                view.quotePostView.usernameLabel.text = "@bob"
                view.quotePostView.isHidden = false
                return view
            }
            .previewLayout(.fixed(width: 375, height: 450))
            .previewDisplayName("text + quote")
        }
    }
}
#endif
