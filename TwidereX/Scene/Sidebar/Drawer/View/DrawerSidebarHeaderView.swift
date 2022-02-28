//
//  DrawerSidebarHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore
import MetaTextKit
import TwidereUI

protocol DrawerSidebarHeaderViewDelegate: AnyObject {
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, avatarButtonDidPressed button: UIButton)
//    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, nameButtonDidPressed button: UIButton)
//    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, usernameButtonDidPressed button: UIButton)

    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, menuButtonDidPressed button: UIButton)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, closeButtonDidPressed button: UIButton)
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView)
}

final class DrawerSidebarHeaderView: UIView {
    
    static var avatarViewSize = CGSize(width: 40, height: 40)
    
    weak var delegate: DrawerSidebarHeaderViewDelegate?
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    let avatarView: ProfileAvatarView = {
        let avatarView = ProfileAvatarView()
        avatarView.setup(dimension: .inline)
        return avatarView
    }()
    
    let nameMetaLabel: MetaLabel = {
        let label = MetaLabel(style: .sidebarAuthorName)
        label.configure(content: PlaintextMetaContent(string: "Alice"))
        return label
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let usernameLabel: PlainLabel = {
        let label = PlainLabel(style: .sidebarAuthorUsername)
        label.text = "@alice"
        return label
    }()
    
    let menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    let profileDashboardView: ProfileDashboardView = {
        let profileDashboardView = ProfileDashboardView()
        profileDashboardView.isAllowAdaptiveLayout = false
        return profileDashboardView
    }()

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
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.addArrangedSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: DrawerSidebarHeaderView.avatarViewSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: DrawerSidebarHeaderView.avatarViewSize.height).priority(.required - 1),
        ])
        
        let nameStackView = UIStackView()
        infoStackView.addArrangedSubview(nameStackView)
        nameStackView.axis = .vertical
        nameStackView.alignment = .leading
        nameStackView.distribution = .fillProportionally
        
        let nameAndLockContainerView = UIView()
        nameMetaLabel.translatesAutoresizingMaskIntoConstraints = false
        nameAndLockContainerView.addSubview(nameMetaLabel)
        NSLayoutConstraint.activate([
            nameMetaLabel.topAnchor.constraint(equalTo: nameAndLockContainerView.topAnchor),
            nameMetaLabel.leadingAnchor.constraint(equalTo: nameAndLockContainerView.leadingAnchor),
            nameMetaLabel.bottomAnchor.constraint(equalTo: nameAndLockContainerView.bottomAnchor),
        ])
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        nameAndLockContainerView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.centerYAnchor.constraint(equalTo: nameMetaLabel.centerYAnchor),
            lockImageView.leadingAnchor.constraint(equalTo: nameMetaLabel.trailingAnchor, constant: 4),
            lockImageView.trailingAnchor.constraint(equalTo: nameAndLockContainerView.trailingAnchor),
        ])
        
        nameStackView.addArrangedSubview(nameAndLockContainerView)
        nameStackView.addArrangedSubview(usernameLabel)
        
        infoStackView.addArrangedSubview(menuButton)
        
        let paddingView = UIView()
        infoStackView.addArrangedSubview(paddingView)
        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        infoStackView.addArrangedSubview(closeButton)
        
        containerStackView.addArrangedSubview(profileDashboardView)
        
        avatarView.avatarButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.avatarButtonDidPressed(_:)), for: .touchUpInside)
//        nameButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.nameButtonDidPressed(_:)), for: .touchUpInside)
//        usernameLabel.addTarget(self, action: #selector(DrawerSidebarHeaderView.usernameButtonDidPressed(_:)), for: .touchUpInside)
        
        menuButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.menuButtonPressed(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.closeButtonPressed(_:)), for: .touchUpInside)
        
        profileDashboardView.delegate = self
    }
    
}

extension DrawerSidebarHeaderView {
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, avatarButtonDidPressed: sender)
    }
    
//    @objc private func nameButtonDidPressed(_ sender: UIButton) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        delegate?.drawerSidebarHeaderView(self, nameButtonDidPressed: sender)
//    }
//
//    @objc private func usernameButtonDidPressed(_ sender: UIButton) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        delegate?.drawerSidebarHeaderView(self, usernameButtonDidPressed: sender)
//    }
    
    @objc private func menuButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, menuButtonDidPressed: sender)
    }
    
    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, closeButtonDidPressed: sender)
    }
    
}

// MARK: - ProfileDashboardViewDelegate
extension DrawerSidebarHeaderView: ProfileDashboardViewDelegate {
    
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.drawerSidebarHeaderView(self, profileDashboardView: dashboardView, followingMeterViewDidPressed: meterView)
    }
    
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.drawerSidebarHeaderView(self, profileDashboardView: dashboardView, followersMeterViewDidPressed: meterView)
    }
    
    func profileDashboardView(_ dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.drawerSidebarHeaderView(self, profileDashboardView: dashboardView, listedMeterViewDidPressed: meterView)
    }
    
}

#if DEBUG
import SwiftUI

struct DrawerSidebarHeaderView_Previews: PreviewProvider {
    
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            let header = DrawerSidebarHeaderView()
            // header.avatarView.setImage(avatarImage, for: .normal)
            return header
        }
        .previewLayout(.fixed(width: 375, height: 140))
    }
}
#endif
