//
//  ListUserStyleTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-3-8.
//

import UIKit
import Combine
import TwidereCore
import MetaTextKit

public final class ListUserStyleTableViewCell: UITableViewCell {
    
    public let avatarButton = AvatarButton()
    
    public let usernameLabel = PlainLabel(style: .statusAuthorUsername)
    
    public let listNameLabel = PlainLabel(style: .statusContent)
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarButton.avatarImageView.prepareForResuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ListUserStyleTableViewCell {
    
    private func _init() {
        // container: V - [ userContainerView | listNameLabel ]
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 5
        
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 12),
        ])
        
        // userContainerView: H - [ avatarButton | usernameLabel ]
        let userContainerView = UIStackView()
        userContainerView.axis = .horizontal
        userContainerView.spacing = 8
        container.addArrangedSubview(userContainerView)
        
        // avatarButton
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        userContainerView.addArrangedSubview(avatarButton)
        userContainerView.addArrangedSubview(usernameLabel)
        NSLayoutConstraint.activate([
            avatarButton.heightAnchor.constraint(equalTo: usernameLabel.heightAnchor).priority(.required - 1),
            avatarButton.widthAnchor.constraint(equalTo: usernameLabel.heightAnchor).priority(.required - 1),
        ])
        avatarButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        avatarButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        avatarButton.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        avatarButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        usernameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        // listNameLabel
        container.addArrangedSubview(listNameLabel)
        
        avatarButton.isUserInteractionEnabled = false
    }
    
}
