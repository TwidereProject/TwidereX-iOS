//
//  StatusView.swift
//  StatusView
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Combine
import UIKit
import MetaTextKit
import MetaTextArea

final class StatusView: UIView {
    
    var disposeBag = Set<AnyCancellable>()

    static let bodyContainerStackViewSpacing: CGFloat = 10
    
    // header
    let headerContainerView = UIView()
    let headerIconImageView = UIImageView()
    static var headerTextLabelStyle: UILabel.Style { .statusHeader }
    let headerTextLabel = MetaLabel(style: .statusHeader)
    
    // avatar
    static let authorAvatarButtonSize = CGSize(width: 44, height: 44)
    let authorAvatarButton = AvatarButton()
    
    // author
    static var authorNameLabelStyle: UILabel.Style { .statusAuthorName }
    let authorNameLabel = MetaLabel(style: StatusView.authorNameLabelStyle)
    let authorUsernameLabel = PlainLabel(style: .statusAuthorUsername)
    let visibilityImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    let timestampLabel = PlainLabel(style: .statusTimestamp)
    
    // content
    let contentTextView: MetaTextAreaView = {
        let textView = MetaTextAreaView()
        return textView
    }()
    
    // toolbar
    let toolbar = StatusToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusView {
    
    func prepareForReuse() {
        authorAvatarButton.avatarImageView.cancelTask()
        headerContainerView.isHidden = true
    }
    
    private func _init() {
        // container: V - [ header container | body container ]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // header container: H - [ icon | label ]
        containerStackView.addArrangedSubview(headerContainerView)
        headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerIconImageView)
        headerContainerView.addSubview(headerTextLabel)
        NSLayoutConstraint.activate([
            headerTextLabel.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerTextLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            headerTextLabel.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerIconImageView.centerYAnchor.constraint(equalTo: headerTextLabel.centerYAnchor),
            headerIconImageView.heightAnchor.constraint(equalTo: headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            headerIconImageView.widthAnchor.constraint(equalTo: headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
            headerTextLabel.leadingAnchor.constraint(equalTo: headerIconImageView.trailingAnchor, constant: 4),
            // align to author name below
        ])
        headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerContainerView.isHidden = true
        
        // body container: H - [ authorAvatarButton | content container ]
        let bodyContainerStackView = UIStackView()
        bodyContainerStackView.axis = .horizontal
        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
        bodyContainerStackView.alignment = .top
        containerStackView.addArrangedSubview(bodyContainerStackView)
        
        // authorAvatarButton
        authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        bodyContainerStackView.addArrangedSubview(authorAvatarButton)
        NSLayoutConstraint.activate([
            authorAvatarButton.widthAnchor.constraint(equalToConstant: StatusView.authorAvatarButtonSize.width).priority(.required - 1),
            authorAvatarButton.heightAnchor.constraint(equalToConstant: StatusView.authorAvatarButtonSize.height).priority(.required - 1),
        ])
        authorAvatarButton.avatarImageView.imageViewSize = StatusView.authorAvatarButtonSize
        
        // content container: V - [ author content | contentTextView | … | toolbar ]
        let contentContainerView = UIStackView()
        contentContainerView.axis = .vertical
        bodyContainerStackView.addArrangedSubview(contentContainerView)
        
        // author content: H - [ authorNameLabel | authorUsernameLabel | padding | visibilityImageView (for Mastodon) | timestampLabel ]
        let authorContentStackView = UIStackView()
        authorContentStackView.axis = .horizontal
        authorContentStackView.spacing = 6
        contentContainerView.addArrangedSubview(authorContentStackView)
        contentContainerView.setCustomSpacing(4, after: authorContentStackView)
        
        authorContentStackView.addArrangedSubview(authorNameLabel)
        authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        authorContentStackView.addArrangedSubview(authorUsernameLabel)
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
        authorContentStackView.addArrangedSubview(UIView()) // padding
        authorContentStackView.addArrangedSubview(timestampLabel)
        timestampLabel.setContentHuggingPriority(.required - 9, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
        
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addArrangedSubview(contentTextView)
        contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
        
        NSLayoutConstraint.activate([
            headerTextLabel.leadingAnchor.constraint(equalTo: authorNameLabel.leadingAnchor),
        ])
        
        contentContainerView.addArrangedSubview(toolbar)
        toolbar.setContentHuggingPriority(.required - 9, for: .vertical)
        
        ThemeService.shared.theme
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.update(theme: theme)
            }
            .store(in: &disposeBag)
    }

}

extension StatusView {
    
    private func update(theme: Theme) {
        headerIconImageView.tintColor = theme.accentColor
    }
    
    func setHeaderDisplay() {
        headerContainerView.isHidden = false
    }
}
