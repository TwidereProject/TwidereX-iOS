//
//  UserView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import MetaTextKit

protocol UserViewDelegate: AnyObject {
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
}

final class UserView: UIView {
    
    let logger = Logger(subsystem: "UserView", category: "UI")

    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    var disposeBag = Set<AnyCancellable>()          // clear when reuse
    
    weak var delegate: UserViewDelegate?
    
    private var style: Style?
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userView: self)
        return viewModel
    }()
    
    let containerStackView = UIStackView()

    // avatar
    let authorProfileAvatarView = ProfileAvatarView()
    
    // name
    let nameLabel = MetaLabel(style: .userAuthorName)
    
    // username
    let usernameLabel = PlainLabel(style: .userAuthorUsername)
    
    // followerCount
    let followerCountLabel = PlainLabel(style: .userDescription)
    
    // friendship control
    let friendshipButton = FriendshipButton()
    
    func prepareForReuse() {
        disposeBag.removeAll()
        viewModel.avatarImageURL = nil
        authorProfileAvatarView.avatarButton.avatarImageView.cancelTask()
        Style.prepareForReuse(userView: self)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension UserView {
    private func _init() {
        // container: H - [ user avatar | info container | accessory container ]
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
        
        authorProfileAvatarView.scale = 0.5
        containerStackView.addArrangedSubview(authorProfileAvatarView)
        
        authorProfileAvatarView.isUserInteractionEnabled = false
        nameLabel.isUserInteractionEnabled = false
        usernameLabel.isUserInteractionEnabled = false
        followerCountLabel.isUserInteractionEnabled = false
    }
    
    func setup(style: Style) {
        guard self.style == nil else {
            assertionFailure("Should only setup once")
            return
        }
        self.style = style
        style.layout(userView: self)
        Style.prepareForReuse(userView: self)
    }
}

extension UserView {
    enum Style {
        // headline: name | username
        // subheadline: follower count
        // accessory: none
        case plain
        // headline: name | username
        // subheadline: follower count
        // accessory: follow button
        case friendship
        
        func layout(userView: UserView) {
            switch self {
            case .plain:        layoutPlain(userView: userView)
            case .friendship:   layoutFriendship(userView: userView)
            }
        }
        
        static func prepareForReuse(userView: UserView) {
            
        }
    }
}

extension UserView.Style {
    // FIXME:
    func layoutPlain(userView: UserView) {
        let infoContainerStackView = UIStackView()
        userView.containerStackView.addArrangedSubview(infoContainerStackView)
        infoContainerStackView.axis = .vertical
        infoContainerStackView.distribution = .fillEqually
        
        infoContainerStackView.addArrangedSubview(userView.nameLabel)
        infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.setNeedsLayout()
    }
    
    // FIXME:
    func layoutFriendship(userView: UserView) {
        let infoContainerStackView = UIStackView()
        userView.containerStackView.addArrangedSubview(infoContainerStackView)
        infoContainerStackView.axis = .vertical
        infoContainerStackView.distribution = .fillEqually
        
        infoContainerStackView.addArrangedSubview(userView.nameLabel)
        infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.friendshipButton.translatesAutoresizingMaskIntoConstraints = false
        userView.containerStackView.addArrangedSubview(userView.friendshipButton)
        NSLayoutConstraint.activate([
            userView.friendshipButton.widthAnchor.constraint(equalToConstant: 80),  // maybe dynamic width for different language?
        ])
        
        userView.setNeedsLayout()
    }
}
