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
    static let lockImageViewSize = CGSize(width: 16, height: 16)
    
    let retweetContainerStackView = UIStackView()
    
    let retweetIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let retweetInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        label.text = "Bob Retweeted"
        return label
    }()
    
    let avatarImageView = UIImageView()
    
    let verifiedBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.verifiedBadgeMini.image.withRenderingMode(.alwaysOriginal)
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.text = "Alice"
        return label
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
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
    let activeTextLabel = ActiveLabel(style: .default)

    let mosaicImageView = MosaicImageView()
    let quotePostView = QuotePostView()
    
    let geoContainerStackView = UIStackView()
    let geoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 6)
        button.imageView?.tintColor = .secondaryLabel
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setImage(Asset.ObjectTools.mappinMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.isUserInteractionEnabled = false
        return button
    }()
    
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
        // container: [retweet | post]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
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
            retweetIconImageView.widthAnchor.constraint(equalToConstant: 12).priority(.required - 1),
            retweetIconImageView.heightAnchor.constraint(equalToConstant: 12).priority(.required - 1),
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
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            verifiedBadgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            verifiedBadgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
        ])

        // tweet container: [user meta container | main container | action toolbar]
        let tweetContainerStackView = UIStackView()
        postContainerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .vertical
        tweetContainerStackView.spacing = 2
        
        // user meta container: [name | lock | username | date | menu]
        let userMetaContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(lockImageView)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        userMetaContainerStackView.addArrangedSubview(dateLabel)
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        userMetaContainerStackView.addArrangedSubview(moreMenuButton)
        NSLayoutConstraint.activate([
            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
            moreMenuButton.heightAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh + 10, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        lockImageView.setContentHuggingPriority(.defaultHigh + 5, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh + 3, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        moreMenuButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // align retweet label leading to name
        // align retweet icon trailing to avatar
        NSLayoutConstraint.activate([
            retweetInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            retweetIconImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        ])
        
        // main container: [text | image | quote | geo]
        tweetContainerStackView.addArrangedSubview(mainContainerStackView)
        mainContainerStackView.axis = .vertical
        mainContainerStackView.spacing = 8
        activeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(activeTextLabel)
        mosaicImageView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(mosaicImageView)
        mainContainerStackView.addArrangedSubview(quotePostView)
        mainContainerStackView.addArrangedSubview(geoContainerStackView)
        activeTextLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // geo container: [geo | (padding)]
        geoContainerStackView.axis = .horizontal
        geoContainerStackView.distribution = .fill
        geoContainerStackView.addArrangedSubview(geoButton)
        geoContainerStackView.addArrangedSubview(UIView())
        
        // action toolbar
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        tweetContainerStackView.addArrangedSubview(actionToolbar)
        actionToolbar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        verifiedBadgeImageView.isHidden = true
        retweetContainerStackView.isHidden = true
        mosaicImageView.isHidden = true
        quotePostView.isHidden = true
        geoContainerStackView.isHidden = true
        
        // TODO:
        moreMenuButton.isHidden = true
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
                view.verifiedBadgeImageView.isHidden = false
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
            .previewDisplayName("text + image + quote")
        }
    }
}
#endif
