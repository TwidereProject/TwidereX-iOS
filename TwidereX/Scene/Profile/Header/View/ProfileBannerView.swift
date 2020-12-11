//
//  ProfileBannerView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import os.log
import UIKit
import ActiveLabel

protocol ProfileBannerViewDelegate: class {
    func profileBannerView(_ profileBannerView: ProfileBannerView, linkButtonDidPressed button: UIButton)
    func profileBannerView(_ profileBannerView: ProfileBannerView, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity)
}

final class ProfileBannerView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 72, height: 72)
    static let avatarImageViewBackgroundSize = CGSize(width: 72 + 2 * 4, height: 72 + 2 * 4)    // 4pt outside border
    
    weak var delegate: ProfileBannerViewDelegate?
    
    let profileBannerContainer = UIView()
    let profileBannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: Asset.Colors.hightLight.color)
        imageView.layer.masksToBounds = true
        return imageView
    }()
    var profileBannerImageViewTopLayoutConstraint: NSLayoutConstraint!
    
    let profileAvatarImageViewBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 0.5 * ProfileBannerView.avatarImageViewBackgroundSize.width
        return view
    }()
    
    let profileAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        let placeholderImage = UIImage
            .placeholder(size: ProfileBannerView.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        imageView.image = placeholderImage
        return imageView
    }()
    
    let verifiedBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.image = Asset.ObjectTools.verifiedBadge.image.withRenderingMode(.alwaysOriginal)
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 3
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
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
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.text = "@alice"
        return label
    }()
    
    let profileBannerInfoActionView = ProfileBannerInfoActionView()
    
    let bioLabel = ActiveLabel(style: .default)
    
    let linkContainer = UIStackView()
    let linkIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.globeMini.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    var linkIconImageViewHeightAnchor: NSLayoutConstraint!
    var linkIconImageViewWidthAnchor: NSLayoutConstraint!
    let linkButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.setTitle("https://twidere.com", for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let geoContainer = UIStackView()
    let geoIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.mappinMini.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    var geoIconImageViewHeightAnchor: NSLayoutConstraint!
    var geoIconImageViewWidthAnchor: NSLayoutConstraint!
    let geoButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.setTitle("Earth, Galaxy", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(UIColor.secondaryLabel.withAlphaComponent(0.5), for: .highlighted)
        button.titleLabel?.allowsDefaultTighteningForTruncation = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        return button
    }()
    
    let profileBannerStatusView = ProfileBannerStatusView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileBannerView {
    private func _init() {
        // banner
        
        profileBannerContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileBannerContainer)
        NSLayoutConstraint.activate([
            profileBannerContainer.topAnchor.constraint(equalTo: topAnchor),
            profileBannerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: profileBannerContainer.trailingAnchor),
            profileBannerContainer.widthAnchor.constraint(equalTo: profileBannerContainer.heightAnchor, multiplier: 3),
        ])
        
        profileBannerImageView.translatesAutoresizingMaskIntoConstraints = false
        profileBannerContainer.addSubview(profileBannerImageView)
        profileBannerImageViewTopLayoutConstraint = profileBannerImageView.topAnchor.constraint(equalTo: profileBannerContainer.topAnchor)
        NSLayoutConstraint.activate([
            profileBannerImageViewTopLayoutConstraint,
            profileBannerImageView.leadingAnchor.constraint(equalTo: profileBannerContainer.leadingAnchor),
            profileBannerContainer.trailingAnchor.constraint(equalTo: profileBannerImageView.trailingAnchor),
            profileBannerImageView.bottomAnchor.constraint(equalTo: profileBannerContainer.bottomAnchor),
        ])
        
        // avatar
        profileAvatarImageViewBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileAvatarImageViewBackground)
        NSLayoutConstraint.activate([
            profileAvatarImageViewBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileAvatarImageViewBackground.centerYAnchor.constraint(equalTo: profileBannerImageView.bottomAnchor),
            profileAvatarImageViewBackground.widthAnchor.constraint(equalToConstant: ProfileBannerView.avatarImageViewBackgroundSize.width).priority(.required - 1),
            profileAvatarImageViewBackground.heightAnchor.constraint(equalToConstant: ProfileBannerView.avatarImageViewBackgroundSize.height).priority(.required - 1),
        ])
        
        profileAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileAvatarImageView)
        NSLayoutConstraint.activate([
            profileAvatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileAvatarImageView.centerYAnchor.constraint(equalTo: profileBannerImageView.bottomAnchor),
            profileAvatarImageView.widthAnchor.constraint(equalToConstant: ProfileBannerView.avatarImageViewSize.width),
            profileAvatarImageView.heightAnchor.constraint(equalToConstant: ProfileBannerView.avatarImageViewSize.height),
        ])
        
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            verifiedBadgeImageView.trailingAnchor.constraint(equalTo: profileAvatarImageView.trailingAnchor),
            verifiedBadgeImageView.bottomAnchor.constraint(equalTo: profileAvatarImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 24),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        // container: [info | bio | link | geo | status]
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: profileAvatarImageView.bottomAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        containerStackView.preservesSuperviewLayoutMargins = true
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        
        // info: [name (lock), username | bannerInfoActionView]
        let infoContainer = UIView()
        containerStackView.addArrangedSubview(infoContainer)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
        ])
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            lockImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
        ])
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            infoContainer.bottomAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
        ])
        let alignmentLabel = UILabel()
        alignmentLabel.text = " "
        alignmentLabel.isHidden = true
        alignmentLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(alignmentLabel)
        NSLayoutConstraint.activate([
            alignmentLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            alignmentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
        ])
        profileBannerInfoActionView.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(profileBannerInfoActionView)
        NSLayoutConstraint.activate([
            profileBannerInfoActionView.leadingAnchor.constraint(greaterThanOrEqualTo: lockImageView.trailingAnchor, constant: 8.0),
            profileBannerInfoActionView.leadingAnchor.constraint(greaterThanOrEqualTo: usernameLabel.trailingAnchor, constant: 8.0),
            profileBannerInfoActionView.followActionButton.centerYAnchor.constraint(equalTo: alignmentLabel.centerYAnchor),
            infoContainer.trailingAnchor.constraint(equalTo: profileBannerInfoActionView.trailingAnchor),
        ])
        profileBannerInfoActionView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        profileBannerInfoActionView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // bio
        containerStackView.addArrangedSubview(bioLabel)
        
        // link container: [link icon | link]
        containerStackView.addArrangedSubview(linkContainer)
        linkContainer.axis = .horizontal
        linkContainer.distribution = .fill
        linkContainer.spacing = 6
        linkIconImageView.translatesAutoresizingMaskIntoConstraints = false
        linkContainer.addArrangedSubview(linkIconImageView)
        linkIconImageViewWidthAnchor = linkIconImageView.heightAnchor.constraint(equalToConstant: 16)
        linkIconImageViewHeightAnchor = linkIconImageView.widthAnchor.constraint(equalToConstant: 16).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            linkIconImageViewWidthAnchor,
            linkIconImageViewHeightAnchor,
        ])
        linkContainer.addArrangedSubview(linkButton)
        let linkPadding = UIView()
        linkContainer.addArrangedSubview(linkPadding)
        linkIconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        linkIconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // geo container: [link icon | link]
        containerStackView.addArrangedSubview(geoContainer)
        geoContainer.axis = .horizontal
        geoContainer.distribution = .fill
        geoContainer.spacing = 6
        geoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        geoContainer.addArrangedSubview(geoIconImageView)
        geoIconImageViewWidthAnchor = geoIconImageView.heightAnchor.constraint(equalToConstant: 16)
        geoIconImageViewHeightAnchor = geoIconImageView.widthAnchor.constraint(equalToConstant: 16).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            geoIconImageViewWidthAnchor,
            geoIconImageViewHeightAnchor,
        ])
        geoContainer.addArrangedSubview(geoButton)
        let geoPadding = UIView()
        geoContainer.addArrangedSubview(geoPadding)
        geoIconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        geoIconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // status
        containerStackView.addArrangedSubview(profileBannerStatusView)
        
        verifiedBadgeImageView.isHidden = true
        lockImageView.isHidden = true
        profileBannerInfoActionView.followStatusLabel.isHidden = true
        linkButton.addTarget(self, action: #selector(ProfileBannerView.linkButtonDidPressed(_:)), for: .touchUpInside)
        
        bioLabel.delegate = self
        
        bringSubviewToFront(profileAvatarImageView)
        bringSubviewToFront(verifiedBadgeImageView)
    }

}

extension ProfileBannerView {
    @objc private func linkButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileBannerView(self, linkButtonDidPressed: sender)
    }
}

// MARK: - ActiveLabelDelegate
extension ProfileBannerView: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.profileBannerView(self, activeLabel: activeLabel, didTapEntity: entity)
    }
}

#if DEBUG
import SwiftUI

struct ProfileBannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let banner = ProfileBannerView()
                banner.profileBannerImageView.image = UIImage(named: "peter-luo")
                return banner
            }
            .previewLayout(.fixed(width: 375, height: 800))
            UIViewPreview(width: 375) {
                let banner = ProfileBannerView()
                banner.profileBannerImageView.image = UIImage(named: "peter-luo")
                return banner
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 800))
        }
    }
}
#endif
