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
    // func userView(_ userView: UserView, authorAvatarButtonDidPressed button: AvatarButton)
    func userView(_ userView: UserView, menuActionDidPressed action: UserView.MenuAction, menuButton button: UIButton)
}

public final class UserView: UIView {
    
    let logger = Logger(subsystem: "UserView", category: "UI")
    
    public static let avatarImageViewSize = CGSize(width: 44, height: 44)

    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    var disposeBag = Set<AnyCancellable>()          // clear when reuse
    
    weak var delegate: UserViewDelegate?
    
    private(set) var style: Style?
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userView: self)
        return viewModel
    }()
    
    // container
    public let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    public static var contentStackViewSpacing: CGFloat = 10
    public let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = UserView.contentStackViewSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    public let infoContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    public let accessoryContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()
    
    // header
    public let headerContainerView = UIView()
    public let headerIconImageView = UIImageView()
    public static var headerTextLabelStyle: TextStyle { .statusHeader }
    public let headerTextLabel = MetaLabel(style: .statusHeader)

    // avatar
    public let authorProfileAvatarView: ProfileAvatarView = {
        let profileAvatarView = ProfileAvatarView()
        profileAvatarView.setup(dimension: .inline)
        return profileAvatarView
    }()
    
    // name
    public let nameLabel = MetaLabel(style: .userAuthorName)
    
    // username
    public let usernameLabel = PlainLabel(style: .userAuthorUsername)
    
    // lock
    public let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFill
        imageView.image = Asset.ObjectTools.lockMiniInline.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    // followerCount
    public let followerCountLabel = PlainLabel(style: .userDescription)
    
    // friendship control
    public let friendshipButton: FriendshipButton = {
        let button = FriendshipButton()
        button.titleFont = UIFontMetrics(forTextStyle: .headline)
            .scaledFont(for: UIFont.systemFont(ofSize: 13, weight: .semibold))
        return button
    }()
    
    // checkmark control
    public let checkmarkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    
    // menu control
    public let menuButton: HitTestExpandedButton = {
        let button = HitTestExpandedButton()
        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    
    // activity indicator
    public let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        viewModel.avatarImageURL = nil
        authorProfileAvatarView.avatarButton.avatarImageView.cancelTask()
        Style.prepareForReuse(userView: self)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension UserView {
    public enum MenuAction: Hashable {
        case signOut
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
        authorProfileAvatarView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(authorProfileAvatarView)
        NSLayoutConstraint.activate([
            authorProfileAvatarView.widthAnchor.constraint(equalToConstant: UserView.avatarImageViewSize.width).priority(.required - 1),
            authorProfileAvatarView.heightAnchor.constraint(equalToConstant: UserView.avatarImageViewSize.height).priority(.required - 1),
        ])
        contentStackView.addArrangedSubview(infoContainerStackView)
        contentStackView.addArrangedSubview(accessoryContainerView)
        
        authorProfileAvatarView.isUserInteractionEnabled = false
        nameLabel.isUserInteractionEnabled = false
        usernameLabel.isUserInteractionEnabled = false
        followerCountLabel.isUserInteractionEnabled = false
    }
    
    public func setup(style: Style) {
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
    public enum Style {
        // headline: name | lock
        // subheadline: username
        // accessory: menu
        case account
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: follow button
        case relationship
        // headline: name | lock
        // subheadline: username
        // accessory: action button
        case friendship
        // header: notification
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: none // TODO: menu
        case notification
        // headline: name | lock
        // subheadline: username
        // accessory: checkmark button
        case mentionPick
        
        public func layout(userView: UserView) {
            switch self {
            case .account:          layoutAccount(userView: userView)
            case .relationship:     layoutRelationship(userView: userView)
            case .friendship:       layoutFriendship(userView: userView)
            case .notification:     layoutNotification(userView: userView)
            case .mentionPick:      layoutMentionPick(userView: userView)
            }
        }
        
        public static func prepareForReuse(userView: UserView) {
            userView.headerContainerView.isHidden = true
        }
    }
}

extension UserView.Style {
    // FIXME: update layout
    func layoutAccount(userView: UserView) {
        let headlineStackView = UIStackView()
        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
        headlineStackView.axis = .horizontal
        headlineStackView.spacing = 6
        headlineStackView.addArrangedSubview(userView.nameLabel)
        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineStackView.addArrangedSubview(userView.lockImageView)
        NSLayoutConstraint.activate([
            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
        ])
        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        headlineStackView.addArrangedSubview(UIView())  // padding
        
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.accessoryContainerView.addArrangedSubview(userView.menuButton)
        userView.menuButton.setContentHuggingPriority(.required - 9, for: .horizontal)
        
        userView.setNeedsLayout()
    }
    
    // FIXME: update layout
    func layoutRelationship(userView: UserView) {
        let headlineStackView = UIStackView()
        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
        headlineStackView.axis = .horizontal
        headlineStackView.spacing = 6
        headlineStackView.addArrangedSubview(userView.nameLabel)
        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineStackView.addArrangedSubview(userView.lockImageView)
        NSLayoutConstraint.activate([
            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
        ])
        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        headlineStackView.addArrangedSubview(UIView())  // padding
        
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.friendshipButton.translatesAutoresizingMaskIntoConstraints = false
        userView.accessoryContainerView.addArrangedSubview(userView.friendshipButton)
        NSLayoutConstraint.activate([
//            userView.friendshipButton.heightAnchor.constraint(equalToConstant: 34).priority(.required - 1),
            userView.friendshipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).priority(.required - 1),
        ])
        userView.friendshipButton.setContentHuggingPriority(.required - 10, for: .horizontal)
        userView.friendshipButton.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        
        userView.setNeedsLayout()
    }
    
    func layoutFriendship(userView: UserView) {
        // headline
        let headlineStackView = UIStackView()
        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
        headlineStackView.axis = .horizontal
        headlineStackView.spacing = 6
        headlineStackView.addArrangedSubview(userView.nameLabel)
        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineStackView.addArrangedSubview(userView.lockImageView)
        NSLayoutConstraint.activate([
            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
        ])
        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        headlineStackView.addArrangedSubview(userView.usernameLabel)
        headlineStackView.addArrangedSubview(UIView())  // padding
        
        // subheadline
        userView.infoContainerStackView.addArrangedSubview(userView.followerCountLabel)
        
        // TODO: menu
        
        userView.setNeedsLayout()
    }
    
    // FIXME: add action button
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

        let headlineStackView = UIStackView()
        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
        headlineStackView.axis = .horizontal
        headlineStackView.spacing = 6
        headlineStackView.addArrangedSubview(userView.nameLabel)
        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineStackView.addArrangedSubview(userView.lockImageView)
        NSLayoutConstraint.activate([
            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
        ])
        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        headlineStackView.addArrangedSubview(UIView())  // padding
        
        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        // set header label align to author name
        NSLayoutConstraint.activate([
            userView.headerTextLabel.leadingAnchor.constraint(equalTo: userView.authorProfileAvatarView.trailingAnchor, constant: UserView.contentStackViewSpacing),
        ])
        
        userView.setNeedsLayout()
    }
    
    func layoutMentionPick(userView: UserView) {
        let headlineStackView = UIStackView()
        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
        headlineStackView.axis = .horizontal
        headlineStackView.spacing = 6
        headlineStackView.addArrangedSubview(userView.nameLabel)
        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineStackView.addArrangedSubview(userView.lockImageView)
        NSLayoutConstraint.activate([
            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
        ])
        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        headlineStackView.addArrangedSubview(UIView())  // padding


        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
        
        userView.accessoryContainerView.addArrangedSubview(userView.checkmarkButton)
        userView.checkmarkButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        userView.checkmarkButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        userView.accessoryContainerView.addArrangedSubview(userView.activityIndicatorView)
        userView.activityIndicatorView.setContentHuggingPriority(.required - 1, for: .horizontal)
        userView.activityIndicatorView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        userView.activityIndicatorView.isHidden = true
        
        userView.setNeedsLayout()
    }
}

extension UserView {
    public func setHeaderDisplay() {
        headerContainerView.isHidden = false
    }
}


#if DEBUG
import SwiftUI
struct UserView_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let userView = UserView()
            userView.setup(style: .account)
            return userView
        }
    }
}
#endif
