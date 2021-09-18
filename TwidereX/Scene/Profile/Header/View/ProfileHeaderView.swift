//
//  ProfileHeaderView.swift
//  ProfileHeaderView
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import MetaTextKit
import MetaTextArea

final class ProfileHeaderView: UIView {
    
    var disposeBag = Set<AnyCancellable>()
    
    static let avatarImageViewSize = CGSize(width: 88, height: 88)
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(profileHeaderView: self)
        return viewModel
    }()
    
    let bannerContainer = UIView()
    let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: .systemFill)
        imageView.layer.masksToBounds = true
        return imageView
    }()
    var bannerImageViewTopLayoutConstraint: NSLayoutConstraint!
    
    let avatarView = ProfileAvatarView()
    
    let nameContainer = UIStackView()
    let protectLockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    let nameLabel = MetaLabel(style: .profileAuthorName)
    let usernameLabel = MetaLabel(style: .profileAuthorUsername)
    
    let friendshipButton = FriendshipButton()
    
    let bioTextAreaView = MetaTextAreaView(style: .profileAuthorBio)
    
    let fieldListView = ProfileFieldListView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileHeaderView {
    private func _init() {
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerContainer)
        NSLayoutConstraint.activate([
            bannerContainer.topAnchor.constraint(equalTo: topAnchor),
            bannerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: bannerContainer.trailingAnchor),
            bannerContainer.widthAnchor.constraint(equalTo: bannerContainer.heightAnchor, multiplier: 3),
        ])
        
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(bannerImageView)
        bannerImageViewTopLayoutConstraint = bannerImageView.topAnchor.constraint(equalTo: bannerContainer.topAnchor)
        NSLayoutConstraint.activate([
            bannerImageViewTopLayoutConstraint,
            bannerImageView.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor),
            bannerContainer.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor),
            bannerImageView.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
        ])
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
        ])
        
        // container: V - [ name container | usernameLabel | friendshipButton | bioTextAreaView | … ]
        let container = UIStackView()
        container.spacing = 16
        container.axis = .vertical
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // name container
        nameContainer.axis = .horizontal
        nameContainer.alignment = .center
        nameContainer.spacing = 2
        container.addArrangedSubview(nameContainer)
        container.setCustomSpacing(0, after: nameContainer)
        
        protectLockImageView.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addSubview(protectLockImageView)
        nameLabel.frame.size.width = 9999   // set initial width to workaround sometimes line wrap on short text issue
        nameContainer.addArrangedSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: protectLockImageView.trailingAnchor, constant: 4),
            protectLockImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            protectLockImageView.heightAnchor.constraint(equalTo: nameLabel.heightAnchor, multiplier: 0.5).priority(.required - 1), // 0.5x name height
            protectLockImageView.widthAnchor.constraint(equalTo: protectLockImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        nameLabel.setContentHuggingPriority(.required - 5, for: .horizontal)
        nameLabel.setContentHuggingPriority(.required - 5, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        protectLockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        protectLockImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        // usernameLabel
        container.addArrangedSubview(usernameLabel)
        container.setCustomSpacing(6, after: usernameLabel)
        
        // friendshipButton
        friendshipButton.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(friendshipButton)
        NSLayoutConstraint.activate([
            friendshipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).priority(.required - 1),
            // friendshipButton.heightAnchor.constraint(equalToConstant: FriendshipButton.height).priority(.required - 1),
        ])
        
        // bioTextAreaView
        bioTextAreaView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(bioTextAreaView)
        NSLayoutConstraint.activate([
            bioTextAreaView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bioTextAreaView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        // fieldListView
        fieldListView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(fieldListView)
        NSLayoutConstraint.activate([
            fieldListView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            fieldListView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }
}
