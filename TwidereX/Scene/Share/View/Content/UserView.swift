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
    
    public static let avatarImageViewSize = CGSize(width: 44, height: 44)

    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    var disposeBag = Set<AnyCancellable>()          // clear when reuse
    
    weak var delegate: UserViewDelegate?
    
    private var style: Style?
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userView: self)
        return viewModel
    }()
    
    // container
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    static var contentStackViewSpacing: CGFloat = 10
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = UserView.contentStackViewSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    let infoContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    let accessoryContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()
    
    // header
    let headerContainerView = UIView()
    let headerIconImageView = UIImageView()
    static var headerTextLabelStyle: TextStyle { .statusHeader }
    let headerTextLabel = MetaLabel(style: .statusHeader)

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
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // container:: V - [ header container | content ]
        containerStackView.addArrangedSubview(headerContainerView)
        containerStackView.addArrangedSubview(contentStackView)
        
        // content: H - [ user avatar | info container | accessory container ]
        authorProfileAvatarView.dimension = UserView.avatarImageViewSize.width
        contentStackView.addArrangedSubview(authorProfileAvatarView)
        contentStackView.addArrangedSubview(infoContainerStackView)
        contentStackView.addArrangedSubview(accessoryContainerView)
        
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
        // header: notification
        // headline: name
        // subheadline: username
        // accessory: action button
        case notification
        
        func layout(userView: UserView) {
            switch self {
            case .plain:            layoutPlain(userView: userView)
            case .friendship:       layoutFriendship(userView: userView)
            case .notification:     layoutNotification(userView: userView)
            }
        }
        
        static func prepareForReuse(userView: UserView) {
            userView.headerContainerView.isHidden = true
        }
    }
}

extension UserView.Style {
    // FIXME:
    func layoutPlain(userView: UserView) {
        userView.infoContainerStackView.addArrangedSubview(userView.nameLabel)
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.setNeedsLayout()
    }
    
    // FIXME:
    func layoutFriendship(userView: UserView) {
        userView.infoContainerStackView.addArrangedSubview(userView.nameLabel)
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.friendshipButton.translatesAutoresizingMaskIntoConstraints = false
        userView.accessoryContainerView.addArrangedSubview(userView.friendshipButton)
        NSLayoutConstraint.activate([
            userView.friendshipButton.widthAnchor.constraint(equalToConstant: 80),  // maybe dynamic width for different language?
        ])
        
        userView.setNeedsLayout()
    }
    
    func layoutNotification(userView: UserView) {
        userView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        userView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        userView.headerContainerView.addSubview(userView.headerIconImageView)
        userView.headerContainerView.addSubview(userView.headerTextLabel)
        NSLayoutConstraint.activate([
            userView.headerTextLabel.topAnchor.constraint(equalTo: userView.headerContainerView.topAnchor),
            userView.headerTextLabel.bottomAnchor.constraint(equalTo: userView.headerContainerView.bottomAnchor),
            userView.headerTextLabel.trailingAnchor.constraint(equalTo: userView.headerContainerView.trailingAnchor),
            userView.headerIconImageView.centerYAnchor.constraint(equalTo: userView.headerTextLabel.centerYAnchor),
            userView.headerIconImageView.heightAnchor.constraint(equalTo: userView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            userView.headerIconImageView.widthAnchor.constraint(equalTo: userView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
            userView.headerTextLabel.leadingAnchor.constraint(equalTo: userView.headerIconImageView.trailingAnchor, constant: 4),
            // align to author name below
        ])
        userView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        userView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        userView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        userView.infoContainerStackView.addArrangedSubview(userView.nameLabel)
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        // set header label align to author name
        NSLayoutConstraint.activate([
            userView.headerTextLabel.leadingAnchor.constraint(equalTo: userView.authorProfileAvatarView.trailingAnchor, constant: UserView.contentStackViewSpacing),
        ])
        
        userView.setNeedsLayout()
    }
}

extension UserView {
    func setHeaderDisplay() {
        headerContainerView.isHidden = false
    }
}
