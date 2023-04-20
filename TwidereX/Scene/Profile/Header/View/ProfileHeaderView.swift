//
//  ProfileHeaderView.swift
//  ProfileHeaderView
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MetaTextArea
import MetaLabel

protocol ProfileHeaderViewDelegate: AnyObject {
    func profileHeaderView(_ headerView: ProfileHeaderView, friendshipButtonPressed button: UIButton)
    
    func profileHeaderView(_ headerView: ProfileHeaderView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
    func profileHeaderView(_ headerView: ProfileHeaderView, metaLabel: MetaLabel, didSelectMeta meta: Meta)


    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView)
}

final class ProfileHeaderView: UIView {
    
    let logger = Logger(subsystem: "ProfileHeaderView", category: "View")
    var disposeBag = Set<AnyCancellable>()
    
    static let avatarViewSize = CGSize(width: 88, height: 88)
    
    weak var delegate: ProfileHeaderViewDelegate?
    
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
    
    let avatarView: ProfileAvatarView = {
        let avatarView = ProfileAvatarView()
        avatarView.setup(dimension: .plain)
        return avatarView
    }()
    
    let followsYouIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Controls.Friendship.followsYou
        return label
    }()
    
    let nameContainer = UIStackView()
    let protectLockImageViewContainer: UIView = {
        let view = UIView()
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).priority(.required - 10),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).priority(.required - 11),
        ])
        imageView.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        return view
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
            avatarView.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarViewSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarViewSize.height).priority(.required - 1),
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
        
        // name container: H - [protectLockImageViewContainer | nameLabel ]
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
        protectLockImageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addArrangedSubview(protectLockImageViewContainer)
        nameContainer.addArrangedSubview(nameLabel)
        nameContainerTrailingPaddingView.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.addArrangedSubview(nameContainerTrailingPaddingView)
        
        NSLayoutConstraint.activate([
            nameContainerLeadingPaddingView.widthAnchor.constraint(equalTo: nameContainerTrailingPaddingView.widthAnchor).priority(.required - 1),
            protectLockImageViewContainer.heightAnchor.constraint(equalTo: _placeholderNameLabel.heightAnchor).priority(.required - 10),
            protectLockImageViewContainer.widthAnchor.constraint(equalTo: protectLockImageViewContainer.heightAnchor).priority(.required - 11),
        ])
        _placeholderNameLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        protectLockImageViewContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        protectLockImageViewContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        // the lock icon imageView should align to placeholder centerY
        // and keep position when name label more than one line
        
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
        fieldListView.isHidden = true   // default hidden
        
        dashboardView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(dashboardView)
        NSLayoutConstraint.activate([
            dashboardView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dashboardView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        friendshipButton.addTarget(self, action: #selector(ProfileHeaderView.friendshipButtonDidPressed(_:)), for: .touchUpInside)
        
        bioTextAreaView.delegate = self
        fieldListView.delegate = self
        dashboardView.delegate = self
    }
}

extension ProfileHeaderView {
    @objc private func friendshipButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.profileHeaderView(self, friendshipButtonPressed: sender)
    }
}

// MARK: - MetaTextAreaViewDelegate
extension ProfileHeaderView: MetaTextAreaViewDelegate {
    func metaTextAreaView(_ metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did select meta: \(meta.debugDescription)")
        delegate?.profileHeaderView(self, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
    }
}

// MARK: - ProfileFieldListViewDelegate
extension ProfileHeaderView: ProfileFieldListViewDelegate {
    func profileFieldListView(_ profileFieldListView: ProfileFieldListView, profileFieldCollectionViewCell: ProfileFieldCollectionViewCell, profileFieldContentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileHeaderView(self, metaLabel: metaLabel, didSelectMeta: meta)
    }
}

// MARK: - ProfileDashboardViewDelegate
extension ProfileHeaderView: ProfileDashboardViewDelegate {
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.profileHeaderView(self, profileDashboardView: dashboardView, followingMeterViewDidPressed: meterView)
    }
    
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.profileHeaderView(self, profileDashboardView: dashboardView, followersMeterViewDidPressed: meterView)
    }
    
    func profileDashboardView(_ dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.profileHeaderView(self, profileDashboardView: dashboardView, listedMeterViewDidPressed: meterView)
    }
}
