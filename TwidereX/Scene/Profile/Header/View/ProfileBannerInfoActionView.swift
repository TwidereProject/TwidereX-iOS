//
//  ProfileBannerInfoActionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import UIKit

protocol ProfileBannerInfoActionViewDelegate: class {
    func profileBannerInfoActionView(_ profileBannerInfoActionView: ProfileBannerInfoActionView, followActionButtonPressed button: FollowActionButton)
}

final class ProfileBannerInfoActionView: UIView {
    
    weak var delegate: ProfileBannerInfoActionViewDelegate?
    let followActionButton = FollowActionButton()
    
    let followStatusLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Common.Controls.Friendship.followsYou
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
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

extension ProfileBannerInfoActionView {
    private func _init() {
        followActionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(followActionButton)
        NSLayoutConstraint.activate([
            followActionButton.topAnchor.constraint(equalTo: topAnchor),
            followActionButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: followActionButton.trailingAnchor),
            followActionButton.heightAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.height),
            followActionButton.widthAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.width),
        ])
        
        followStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(followStatusLabel)
        NSLayoutConstraint.activate([
            followStatusLabel.topAnchor.constraint(equalTo: followActionButton.bottomAnchor, constant: 2),
            followStatusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: followStatusLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: followStatusLabel.bottomAnchor),
        ])
        
        followActionButton.addTarget(self, action: #selector(ProfileBannerInfoActionView.followActionButtonPressed(_:)), for: .touchUpInside)
    }
}

extension ProfileBannerInfoActionView {
    @objc private func followActionButtonPressed(_ sender: FollowActionButton) {
        delegate?.profileBannerInfoActionView(self, followActionButtonPressed: sender)
    }
}

#if DEBUG
import SwiftUI

struct ProfileBannerInfoActionView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 100) {
            ProfileBannerInfoActionView()
        }
        .previewLayout(.fixed(width: 100, height: 100))
    }
}
#endif
