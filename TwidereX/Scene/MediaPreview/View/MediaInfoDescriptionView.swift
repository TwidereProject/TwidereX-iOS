//
//  MediaInfoDescriptionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

final class MediaInfoDescriptionView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 32, height: 32)
    
    let avatarImageView = UIImageView()
    
    let verifiedBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.verifiedBadgeSmall.image
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.text = "Alice"
        return label
    }()
    
    let activeTextLabel: ActiveLabel = {
        let activeLabel = ActiveLabel(style: .default)
        activeLabel.numberOfLines = 2
        return activeLabel
    }()
    let statusActionToolbar = StatusActionToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MediaInfoDescriptionView {
    private func _init() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        
        // container: [video control | active label | bottom container]
        let containserStackView = UIStackView()
        containserStackView.axis = .vertical
        containserStackView.spacing = 8
        containserStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containserStackView)
        NSLayoutConstraint.activate([
            containserStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containserStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            readableContentGuide.trailingAnchor.constraint(equalTo: containserStackView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containserStackView.bottomAnchor, constant: 8),
        ])
        
        containserStackView.addArrangedSubview(activeTextLabel)
        
        // bottom container: [avatar | name | (padding) | action toolbar ]
        let bottomContainerStackView = UIStackView()
        containserStackView.addArrangedSubview(bottomContainerStackView)
        bottomContainerStackView.axis = .horizontal
        bottomContainerStackView.spacing = 8
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: MediaInfoDescriptionView.avatarImageViewSize.width).priority(.defaultHigh),
            avatarImageView.heightAnchor.constraint(equalToConstant: MediaInfoDescriptionView.avatarImageViewSize.height).priority(.defaultHigh),
        ])
        verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(verifiedBadgeImageView)
        NSLayoutConstraint.activate([
            avatarImageView.trailingAnchor.constraint(equalTo: verifiedBadgeImageView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: verifiedBadgeImageView.bottomAnchor),
            verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 10).priority(.defaultHigh),
            verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 10).priority(.defaultHigh),
        ])
        
        bottomContainerStackView.addArrangedSubview(nameLabel)
        statusActionToolbar.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerStackView.addArrangedSubview(statusActionToolbar)
        NSLayoutConstraint.activate([
            statusActionToolbar.widthAnchor.constraint(equalToConstant: 180).priority(.defaultHigh),
        ])
    }
}

#if DEBUG
import SwiftUI

struct MediaInfoDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            MediaInfoDescriptionView()
        }
        .background(Color.white)
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 375, height: 200))
    }
}
#endif
