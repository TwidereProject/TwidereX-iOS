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
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, menuButtonDidPressed button: UIButton)
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, closeButtonDidPressed button: UIButton)
}

final class DrawerSidebarHeaderView: UIView {
    
    static var avatarImageViewSize = CGSize(width: 40, height: 40)
    
    weak var delegate: DrawerSidebarHeaderViewDelegate?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        let placeholderImage = UIImage
            .placeholder(size: DrawerSidebarHeaderView.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        imageView.image = placeholderImage
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.text = "@alice"
        label.textColor = .secondaryLabel
        return label
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
        infoStackView.spacing = 16
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 40).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40).priority(.required - 1),
        ])
        
        let nameStackView = UIStackView()
        infoStackView.addArrangedSubview(nameStackView)
        nameStackView.axis = .vertical
        nameStackView.addArrangedSubview(nameLabel)
        nameStackView.addArrangedSubview(usernameLabel)
        
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
        
        menuButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.menuButtonPressed(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(DrawerSidebarHeaderView.closeButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension DrawerSidebarHeaderView {
    
    @objc private func menuButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, menuButtonDidPressed: sender)
    }
    
    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.drawerSidebarHeaderView(self, closeButtonDidPressed: sender)
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
            header.avatarImageView.image = avatarImage
            return header
        }
        .previewLayout(.fixed(width: 375, height: 140))
    }
}
#endif
