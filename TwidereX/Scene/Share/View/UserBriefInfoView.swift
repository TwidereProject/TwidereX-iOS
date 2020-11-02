//
//  UserBriefInfoView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class UserBriefInfoView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
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
        label.font = .systemFont(ofSize: 14, weight: .medium)
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
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Followers: -"
        return label
    }()
    
    let followActionButton = FollowActionButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension UserBriefInfoView {
    private func _init() {
        // container: [user avatar | brief info container | more button]
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 10
        containerStackView.alignment = .center
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: UserBriefInfoView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: UserBriefInfoView.avatarImageViewSize.height).priority(.required - 1),
        ])
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            verifiedBadgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            verifiedBadgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
        ])

        // brief info container: [user meta container | detail]
        let briefInfoContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(briefInfoContainerStackView)
        briefInfoContainerStackView.axis = .vertical
        briefInfoContainerStackView.distribution = .fillEqually
        
        // user meta container: [name | lock | username | (padding)]
        let userMetaContainerStackView = UIStackView()
        briefInfoContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(lockImageView)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        let paddingView = UIView()
        userMetaContainerStackView.addArrangedSubview(paddingView)

        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lockImageView.setContentHuggingPriority(.defaultHigh - 1, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh - 2, for: .horizontal)
        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // detail container: [detail]
        let detailContainerStackView = UIStackView()
        briefInfoContainerStackView.addArrangedSubview(detailContainerStackView)
        detailContainerStackView.axis = .horizontal
        detailContainerStackView.alignment = .center
        detailContainerStackView.spacing = 6
        detailContainerStackView.addArrangedSubview(detailLabel)
        
        followActionButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(followActionButton)
        NSLayoutConstraint.activate([
            followActionButton.heightAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.height).priority(.defaultHigh),
            followActionButton.widthAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.width).priority(.required - 1),
        ])
        followActionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        followActionButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        verifiedBadgeImageView.isHidden = true
        lockImageView.isHidden = true
    }
}

#if DEBUG
import SwiftUI

struct UserBriefInfoView_Previews: PreviewProvider {
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
                let view = UserBriefInfoView()
                view.avatarImageView.image = avatarImage
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text")
        }
    }
}
#endif
