//
//  ProfileBannerInfoActionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import UIKit

final class ProfileBannerInfoActionView: UIView {
    
    static let followButtonHeight: CGFloat = 24
    
    let followActionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = ProfileBannerInfoActionView.followButtonHeight * 0.5
        button.layer.borderWidth = 1
        button.layer.borderColor = Asset.Colors.hightLight.color.cgColor
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let followStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Follows you"
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
            followActionButton.heightAnchor.constraint(equalToConstant: ProfileBannerInfoActionView.followButtonHeight),
            followActionButton.widthAnchor.constraint(equalToConstant: 80),
        ])
        
        followStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(followStatusLabel)
        NSLayoutConstraint.activate([
            followStatusLabel.topAnchor.constraint(equalTo: followActionButton.bottomAnchor, constant: 2),
            followStatusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: followStatusLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: followStatusLabel.bottomAnchor),
        ])
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
