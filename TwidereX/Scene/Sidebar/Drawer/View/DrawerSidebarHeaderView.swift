//
//  DrawerSidebarHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

protocol DrawerSidebarHeaderViewDelegate: class {
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, avatarButtonDidPressed button: UIButton)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, nameButtonDidPressed button: UIButton)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, usernameButtonDidPressed button: UIButton)

    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, menuButtonDidPressed button: UIButton)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, closeButtonDidPressed button: UIButton)
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, followingStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, followerStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, listedStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
}

final class DrawerSidebarHeaderView: UIView {
    
    static var avatarImageViewSize = CGSize(width: 40, height: 40)
    
    weak var delegate: DrawerSidebarHeaderViewDelegate?
    
    let avatarButton: UIButton = {
        let button = UIButton()
        let placeholderImage = UIImage
            .placeholder(size: DrawerSidebarHeaderView.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        button.setImage(placeholderImage, for: .normal)
        return button
    }()
    
    let nameButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .preferredFont(withTextStyle: .headline, maxSize: 20)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(UIColor.label.withAlphaComponent(0.5), for: .highlighted)
        button.setTitle("Alice", for: .normal)
        return button
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let usernameButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .preferredFont(withTextStyle: .subheadline, maxSize: 13)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(UIColor.secondaryLabel.withAlphaComponent(0.5), for: .highlighted)
        button.setTitle("@alice", for: .normal)
        return button
    }()
    
    let menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    let profileBannerStatusView = ProfileBannerStatusView()
    
    let separatorLine = UIView.separatorLine
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension DrawerSidebarHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 20),
        ])
        containerStackView.axis = .vertical
        containerStackView.spacing = 20
        
        // info: [avatar | name | menu button | (padding) | close button]
        let infoStackView = UIStackView()
        containerStackView.addArrangedSubview(infoStackView)
        infoStackView.axis = .horizontal
        infoStackView.spacing = 14
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: 40).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: 40).priority(.required - 1),
        ])
        
        let nameStackView = UIStackView()
        infoStackView.addArrangedSubview(nameStackView)
        nameStackView.axis = .vertical
        nameStackView.alignment = .leading
        nameStackView.distribution = .fillProportionally
        
        let nameAndLockContainerView = UIView()
        nameButton.translatesAutoresizingMaskIntoConstraints = false
        nameAndLockContainerView.addSubview(nameButton)
        NSLayoutConstraint.activate([
            nameButton.topAnchor.constraint(equalTo: nameAndLockContainerView.topAnchor),
            nameButton.leadingAnchor.constraint(equalTo: nameAndLockContainerView.leadingAnchor),
            nameButton.bottomAnchor.constraint(equalTo: nameAndLockContainerView.bottomAnchor),
        ])
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        nameAndLockContainerView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.centerYAnchor.constraint(equalTo: nameButton.centerYAnchor),
            lockImageView.leadingAnchor.constraint(equalTo: nameButton.trailingAnchor, constant: 4),
            lockImageView.trailingAnchor.constraint(equalTo: nameAndLockContainerView.trailingAnchor),
        ])
        
        nameStackView.addArrangedSubview(nameAndLockContainerView)
        nameStackView.addArrangedSubview(usernameButton)
        
        infoStackView.addArrangedSubview(menuButton)
        
        let paddingView = UIView()
        infoStackView.addArrangedSubview(paddingView)
        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        infoStackView.addArrangedSubview(closeButton)
        
        containerStackView.addArrangedSubview(profileBannerStatusView)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self))
        ])
        
        avatarButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.avatarButtonDidPressed(_:)), for: .touchUpInside)
        nameButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.nameButtonDidPressed(_:)), for: .touchUpInside)
        usernameButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.usernameButtonDidPressed(_:)), for: .touchUpInside)
        
        menuButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.menuButtonPressed(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.closeButtonPressed(_:)), for: .touchUpInside)
        
        profileBannerStatusView.delegate = self
    }
    
}

extension DrawerSidebarHeaderView {
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, avatarButtonDidPressed: sender)
    }
    
    @objc private func nameButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, nameButtonDidPressed: sender)
    }
    
    @objc private func usernameButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, usernameButtonDidPressed: sender)
    }
    
    @objc private func menuButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, menuButtonDidPressed: sender)
    }
    
    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, closeButtonDidPressed: sender)
    }
    
}

// MARK: - ProfileBannerStatusViewDelegate
extension DrawerSidebarHeaderView: ProfileBannerStatusViewDelegate {
    
    func profileBannerStatusView(_ view: ProfileBannerStatusView, followingStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        delegate?.drawerSidebarHeaderView(self, profileBannerStatusView: view, followingStatusItemViewDidPressed: statusItemView)
    }
    
    func profileBannerStatusView(_ view: ProfileBannerStatusView, followersStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        delegate?.drawerSidebarHeaderView(self, profileBannerStatusView: view, followerStatusItemViewDidPressed: statusItemView)
    }
    
    func profileBannerStatusView(_ view: ProfileBannerStatusView, listedStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        delegate?.drawerSidebarHeaderView(self, profileBannerStatusView: view, listedStatusItemViewDidPressed: statusItemView)
    }

}

// MARK: - AvatarConfigurableView
//extension DrawerSidebarHeaderView: AvatarConfigurableView {
//    static var configurableAvatarImageViewSize: CGSize { return avatarImageViewSize }
//    var configurableAvatarImageView: UIImageView? { return nil }
//    var configurableAvatarButton: UIButton? { return avatarButton }
//    var configurableVerifiedBadgeImageView: UIImageView? { return nil }
//}

#if DEBUG
import SwiftUI

struct DrawerSidebarHeaderView_Previews: PreviewProvider {
    
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            let headerLabel = DrawerSidebarHeaderView()
            headerLabel.avatarButton.setImage(avatarImage, for: .normal)
            return headerLabel
        }
        .previewLayout(.fixed(width: 375, height: 140))
    }
}
#endif
