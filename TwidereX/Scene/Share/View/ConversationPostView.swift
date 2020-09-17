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
    
    let actionToolbar = ConversationPostActionToolbar()
    
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
        backgroundColor = .systemBackground
        
        // container: [user meta | post]
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
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 2),
            lockImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 2),
        ])
        
        // author container: [name | username]
        let authorContainerStackView = UIStackView()
        userMetaContainerStackView.addArrangedSubview(authorContainerStackView)
        authorContainerStackView.axis = .vertical
        authorContainerStackView.spacing = 0

        // name container: [name | more menu]
        let nameContainerStackView = UIStackView()
        authorContainerStackView.addArrangedSubview(nameContainerStackView)
        nameContainerStackView.axis = .horizontal
        nameContainerStackView.addArrangedSubview(nameLabel)
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        nameContainerStackView.addArrangedSubview(moreMenuButton)
        NSLayoutConstraint.activate([
            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
            moreMenuButton.heightAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
        ])
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        moreMenuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        authorContainerStackView.addArrangedSubview(usernameLabel)
        
        // post container: [tweet container]
        let postContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(postContainerStackView)
        postContainerStackView.axis = .horizontal
        postContainerStackView.spacing = 10
        postContainerStackView.alignment = .top
        
        
        // tweet container: [main container | action toolbar]
        let tweetContainerStackView = UIStackView()
        postContainerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .vertical
        tweetContainerStackView.spacing = 2
    
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
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        tweetContainerStackView.addArrangedSubview(actionToolbar)
        NSLayoutConstraint.activate([
            actionToolbar.heightAnchor.constraint(equalToConstant: 48).priority(.defaultHigh),
        ])
        actionToolbar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        lockImageView.isHidden = true
        mosaicImageView.isHidden = true
        quotePostView.isHidden = true
    }
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
