//
//  ProfileBannerView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import UIKit
import ActiveLabel

final class ProfileBannerView: UIView {
    
    let profileBannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: Asset.Colors.hightLight.color)
        imageView.layer.masksToBounds = true
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
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.text = "@alice"
        return label
    }()
    
    let profileBannerInfoActionView = ProfileBannerInfoActionView()
    
    let bioLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.enabledTypes = [.url]
        label.textColor = .label
        label.font = .systemFont(ofSize: 14)
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        label.textColor = .secondaryLabel
        return label
    }()
    
    let linkContainer = UIStackView()
    let linkIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.icBaselineInsertLink.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    let linkButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.setTitle("https://twidere.com", for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let geoContainer = UIStackView()
    let geoIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.icRoundLocationOn.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    let geoButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.setTitle("Earth, Galaxy", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(UIColor.secondaryLabel.withAlphaComponent(0.5), for: .highlighted)
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
        profileBannerImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileBannerImageView)
        NSLayoutConstraint.activate([
            profileBannerImageView.topAnchor.constraint(equalTo: topAnchor),
            profileBannerImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: profileBannerImageView.trailingAnchor),
            profileBannerImageView.widthAnchor.constraint(equalTo: profileBannerImageView.heightAnchor, multiplier: 3),
        ])
        
        // container: [info | bio | link | geo | status]
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: profileBannerImageView.bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        containerStackView.preservesSuperviewLayoutMargins = true
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        
        // info: [name, username | bannerInfoActionView]
        let infoContainer = UIView()
        containerStackView.addArrangedSubview(infoContainer)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
        ])
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            infoContainer.bottomAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
        ])
        profileBannerInfoActionView.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(profileBannerInfoActionView)
        NSLayoutConstraint.activate([
            profileBannerInfoActionView.followActionButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            infoContainer.trailingAnchor.constraint(equalTo: profileBannerInfoActionView.trailingAnchor),
        ])
        
        // bio
        containerStackView.addArrangedSubview(bioLabel)
        
        // link container: [link icon | link]
        containerStackView.addArrangedSubview(linkContainer)
        linkContainer.axis = .horizontal
        linkContainer.distribution = .fill
        linkContainer.spacing = 6
        linkIconImageView.translatesAutoresizingMaskIntoConstraints = false
        linkContainer.addArrangedSubview(linkIconImageView)
        NSLayoutConstraint.activate([
            linkIconImageView.heightAnchor.constraint(equalToConstant: 16),
            linkIconImageView.widthAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
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
        NSLayoutConstraint.activate([
            geoIconImageView.heightAnchor.constraint(equalToConstant: 16),
            geoIconImageView.widthAnchor.constraint(equalToConstant: 16).priority(.defaultHigh),
        ])
        geoContainer.addArrangedSubview(geoButton)
        let geoPadding = UIView()
        geoContainer.addArrangedSubview(geoPadding)
        geoIconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        geoIconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // status
        containerStackView.addArrangedSubview(profileBannerStatusView)
    }
}

#if DEBUG
import SwiftUI

struct ProfileBannerView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            let banner = ProfileBannerView()
            banner.profileBannerImageView.image = UIImage(named: "peter-luo")
            return banner
        }
        .previewLayout(.fixed(width: 375, height: 800))
    }
}
#endif
