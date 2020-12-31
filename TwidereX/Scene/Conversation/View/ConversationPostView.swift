//
//  ConversationPostView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import UIKit
import ActiveLabel

final class ConversationPostView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)

    let retweetContainerStackView = UIStackView()
    
    let retweetIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let retweetInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.text = "Bob Retweeted"
        return label
    }()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
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
    
    let moreMenuButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
        return button
    }()
    
    let geoIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.image = Asset.ObjectTools.mappinMini.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let geoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        label.text = "Earth, Galaxy"
        return label
        
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = "2020/01/01 00:00 PM"
        return label
    }()
    
    let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = Asset.Colors.hightLight.color
        label.text = "Twidere for iOS"
        return label
    }()
    
    let activeTextLabel = ActiveLabel(style: .default)
    let mosaicImageView = MosaicImageView()
    let mosaicPlayerView = MosaicPlayerView()
    let quotePostView = QuotePostView()
    let geoMetaContainerStackView = UIStackView()
    let dateMetaContainer = UIStackView()

    let replyPostStatusView = ConversationPostStatusView()
    let retweetPostStatusView = ConversationPostStatusView()
    let quotePostStatusView = ConversationPostStatusView()
    let likePostStatusView = ConversationPostStatusView()
    let actionToolbar = StatusActionToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ConversationPostView {

    private func _init() {        
        // container: [retweet | user meta | main | meta | action toolbar]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // retweet container: [retweet icon | retweet info]
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
        
        // user meta container: [user avatar | author]
        let userMetaContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.spacing = 10
        userMetaContainerStackView.alignment = .top // should name and username fill all space or not
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        userMetaContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: ConversationPostView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ConversationPostView.avatarImageViewSize.height).priority(.required - 1),
        ])
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            verifiedBadgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            verifiedBadgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        // author container: [name | username]
        let authorContainerStackView = UIStackView()
        userMetaContainerStackView.addArrangedSubview(authorContainerStackView)
        authorContainerStackView.axis = .vertical
        authorContainerStackView.spacing = 0

        // name container: [name | lock | (padding) | more menu]
        let nameContainerStackView = UIStackView()
        authorContainerStackView.addArrangedSubview(nameContainerStackView)
        nameContainerStackView.axis = .horizontal
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameContainerStackView.addArrangedSubview(nameLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameContainerStackView.addArrangedSubview(lockImageView)
        nameContainerStackView.addArrangedSubview(UIView())
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        nameContainerStackView.addArrangedSubview(moreMenuButton)
        NSLayoutConstraint.activate([
            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
            moreMenuButton.heightAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
        ])
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        moreMenuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        authorContainerStackView.addArrangedSubview(usernameLabel)
        
        // align retweet label leading to name
        // align retweet icon trailing to avatar
        NSLayoutConstraint.activate([
            retweetInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            retweetIconImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        ])
    
        // main container: [text | image | quote]
        let mainContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(mainContainerStackView)
        mainContainerStackView.axis = .vertical
        mainContainerStackView.spacing = 8
        activeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(activeTextLabel)
        mainContainerStackView.addArrangedSubview(mosaicImageView)
        mainContainerStackView.addArrangedSubview(mosaicPlayerView)
        mainContainerStackView.addArrangedSubview(quotePostView)
        activeTextLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        activeTextLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // meta container: [geo meta | date meta | status meta]
        let metaContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(metaContainerStackView)
        metaContainerStackView.axis = .vertical
        metaContainerStackView.spacing = 8
        metaContainerStackView.alignment = .center

        // top padding for meta container
        let metaContainerStackViewTopPadding = UIView()
        metaContainerStackViewTopPadding.translatesAutoresizingMaskIntoConstraints = false
        metaContainerStackView.addArrangedSubview(metaContainerStackViewTopPadding)
        NSLayoutConstraint.activate([
            metaContainerStackViewTopPadding.heightAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
        ])

        // geo meta container: [geo icon | geo]
        metaContainerStackView.addArrangedSubview(geoMetaContainerStackView)
        geoMetaContainerStackView.axis = .horizontal
        geoMetaContainerStackView.spacing = 6
        geoMetaContainerStackView.addArrangedSubview(geoIconImageView)
        geoMetaContainerStackView.addArrangedSubview(geoLabel)

        // date meta container: [date | source]
        metaContainerStackView.addArrangedSubview(dateMetaContainer)
        dateMetaContainer.axis = .horizontal
        dateMetaContainer.alignment = .center
        dateMetaContainer.spacing = 8
        dateMetaContainer.addArrangedSubview(dateLabel)
        dateMetaContainer.addArrangedSubview(sourceLabel)
        
        // status meta container: [reply | retweet | quote | like]
        let statusMetaContainer = UIStackView()
        metaContainerStackView.addArrangedSubview(statusMetaContainer)
        statusMetaContainer.axis = .horizontal
        statusMetaContainer.distribution = .fillProportionally
        statusMetaContainer.alignment = .center
        statusMetaContainer.spacing = 20
        
        // reply status
        replyPostStatusView.statusLabel.text = L10n.Common.Countable.Reply.single
        statusMetaContainer.addArrangedSubview(replyPostStatusView)
        
        // retweet status
        retweetPostStatusView.statusLabel.text = L10n.Common.Countable.Retweet.single
        statusMetaContainer.addArrangedSubview(retweetPostStatusView)
        
        // quote status
        quotePostStatusView.statusLabel.text = L10n.Common.Countable.Quote.single
        statusMetaContainer.addArrangedSubview(quotePostStatusView)
        
        // like status
        likePostStatusView.statusLabel.text = L10n.Common.Countable.Like.single
        statusMetaContainer.addArrangedSubview(likePostStatusView)
        
        // action toolbar
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(actionToolbar)
        NSLayoutConstraint.activate([
            actionToolbar.heightAnchor.constraint(equalToConstant: 48).priority(.defaultHigh),
        ])
        actionToolbar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                
        verifiedBadgeImageView.isHidden = true
        lockImageView.isHidden = true
        mosaicImageView.isHidden = true
        mosaicPlayerView.isHidden = true
        quotePostView.isHidden = true
        
        // TODO:
        moreMenuButton.isHidden = true
    }

}

// MARK: - AvatarConfigurableView
extension ConversationPostView: AvatarConfigurableView {
    static var configurableAvatarImageViewSize: CGSize { return avatarImageViewSize }
    var configurableAvatarImageView: UIImageView? { return avatarImageView }
    var configurableAvatarButton: UIButton? { return nil }
    var configurableVerifiedBadgeImageView: UIImageView? { return verifiedBadgeImageView }
}

#if DEBUG
import SwiftUI

struct ConversationPostView_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var avatarImage2: UIImage {
        UIImage(named: "dan-maisey")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            let view = ConversationPostView()
            view.retweetContainerStackView.isHidden = false
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
        .previewLayout(.fixed(width: 375, height: 800))
    }
}
#endif
