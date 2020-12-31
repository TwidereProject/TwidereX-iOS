//
//  MediaInfoDescriptionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import ActiveLabel

protocol MediaInfoDescriptionViewDelegate: class {
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarImageViewDidPressed imageView: UIImageView)
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, activeLabelDidPressed activeLabel: ActiveLabel)
}

final class MediaInfoDescriptionView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 32, height: 32)
    
    weak var delegate: MediaInfoDescriptionViewDelegate?
    
    let avatarImageView = UIImageView()
    
    let verifiedBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.verifiedBadgeSmall.image
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.text = "Alice"
        return label
    }()
    
    let activeLabel: ActiveLabel = {
        let activeLabel = ActiveLabel(style: .default)
        activeLabel.numberOfLines = 2
        activeLabel.lineBreakMode = .byTruncatingTail
        return activeLabel
    }()
    
    let statusActionToolbar = StatusActionToolbar()
    
    let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    let activelabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
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
        
        activeLabel.translatesAutoresizingMaskIntoConstraints = false
        containserStackView.addArrangedSubview(activeLabel)
        activeLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
        
        // bottom container: [avatar | name | (padding) | action toolbar ]
        let bottomContainerStackView = UIStackView()
        containserStackView.addArrangedSubview(bottomContainerStackView)
        bottomContainerStackView.axis = .horizontal
        bottomContainerStackView.spacing = 8
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: MediaInfoDescriptionView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: MediaInfoDescriptionView.avatarImageViewSize.height).priority(.required - 1),
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
        
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(MediaInfoDescriptionView.avatarImageViewTapGestureRecognizerHandler(_:)))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        
        activelabelTapGestureRecognizer.addTarget(self, action: #selector(MediaInfoDescriptionView.activeLabelTapGestureRecognizerHandler(_:)))
        activeLabel.addGestureRecognizer(activelabelTapGestureRecognizer)
    }
    
}

extension MediaInfoDescriptionView {
    
    @objc private func avatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaInfoDescriptionView(self, avatarImageViewDidPressed: avatarImageView)
    }
    
    @objc private func activeLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaInfoDescriptionView(self, activeLabelDidPressed: activeLabel)
    }

}

// MARK: - AvatarConfigurableView
extension MediaInfoDescriptionView: AvatarConfigurableView {
    static var configurableAvatarImageViewSize: CGSize { return avatarImageViewSize }
    var configurableAvatarImageView: UIImageView? { return avatarImageView }
    var configurableAvatarButton: UIButton? { return nil }
    var configurableVerifiedBadgeImageView: UIImageView? { return verifiedBadgeImageView }
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
