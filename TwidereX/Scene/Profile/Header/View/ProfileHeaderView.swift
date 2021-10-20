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
    
    let followsYouIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Controls.Friendship.followsYou
        return label
    }()
    
    let nameContainer = UIStackView()
    let protectLockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    // placeholder for layout
    let _placeholderNameLabel = MetaLabel(style: .profileAuthorName)
    let nameLabel = MetaLabel(style: .profileAuthorName)
    let usernameLabel = MetaLabel(style: .profileAuthorUsername)
    
    let friendshipButton = FriendshipButton()
    
    let bioTextAreaView = MetaTextAreaView(style: .profileAuthorBio)
    
    let fieldListView = ProfileFieldListView()
    
    let dashboardView = ProfileDashboardView()
    
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
        container.distribution = .fill
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // followsYouIndicatorLabel
        followsYouIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(followsYouIndicatorLabel)
        NSLayoutConstraint.activate([
            followsYouIndicatorLabel.topAnchor.constraint(equalTo: avatarView.centerYAnchor, constant: 12),
            followsYouIndicatorLabel.leadingAnchor.constraint(equalTo: container.readableContentGuide.leadingAnchor),
        ])
        
        // name container
        nameContainer.axis = .horizontal
        nameContainer.alignment = .top
        nameContainer.spacing = 2
        nameContainer.distribution = .fill
        nameContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(nameContainer)
        NSLayoutConstraint.activate([
            nameContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor, constant: 16),
        ])
        nameContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        container.setCustomSpacing(0, after: nameContainer)
        
        _placeholderNameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addSubview(_placeholderNameLabel)
        NSLayoutConstraint.activate([
            _placeholderNameLabel.topAnchor.constraint(equalTo: nameContainer.topAnchor),
            _placeholderNameLabel.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor),
            _placeholderNameLabel.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor),
        ])
        _placeholderNameLabel.configure(content: PlaintextMetaContent(string: " "))
        
        let nameContainerLeadingPaddingView = UIView()
        let nameContainerTrailingPaddingView = UIView()
        nameContainerLeadingPaddingView.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addArrangedSubview(nameContainerLeadingPaddingView)
        protectLockImageView.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addArrangedSubview(protectLockImageView)
        nameContainer.addArrangedSubview(nameLabel)
        nameContainerTrailingPaddingView.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addArrangedSubview(nameContainerTrailingPaddingView)
        
        NSLayoutConstraint.activate([
            nameContainerLeadingPaddingView.widthAnchor.constraint(equalTo: nameContainerTrailingPaddingView.widthAnchor).priority(.required - 1),
            protectLockImageView.heightAnchor.constraint(equalTo: _placeholderNameLabel.heightAnchor).priority(.required - 1),
            protectLockImageView.widthAnchor.constraint(equalTo: protectLockImageView.heightAnchor).priority(.required - 2),
        ])
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
        
        dashboardView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(dashboardView)
        NSLayoutConstraint.activate([
            dashboardView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dashboardView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }
}
