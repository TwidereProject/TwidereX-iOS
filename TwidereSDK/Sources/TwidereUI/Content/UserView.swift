//
//  UserView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MetaTextKit
import MetaLabel
import TwidereCore
import Kingfisher

public protocol UserViewDelegate: AnyObject {
    func userView(_ viewModel: UserView.ViewModel, userAvatarButtonDidPressed user: UserRecord)
    func userView(_ viewModel: UserView.ViewModel, menuActionDidPressed action: UserView.ViewModel.MenuAction)
    func userView(_ viewModel: UserView.ViewModel, listMembershipButtonDidPressed user: UserRecord)
    func userView(_ viewModel: UserView.ViewModel, followReqeustButtonDidPressed user: UserRecord, accept: Bool)
}

public struct UserView: View {
    
    @ObservedObject public private(set) var viewModel: ViewModel
    
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var lockImageDimension: CGFloat = 16

    public init(viewModel: UserView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            if dynamicTypeSize < .accessibility1 {
                HStack(alignment: .center, spacing: .zero) {
                    // avatar
                    avatarButton
                        .padding(.trailing, StatusView.hangingAvatarButtonTrailingSpacing)
                    // info
                    VStackLayout(alignment: .leading, spacing: .zero) {
                        headlineView
                        subheadlineView
                    }
                    .frame(alignment: .leading)
                    Spacer()
                    // accessory view
                    accessoryView
                }   // end HStack
                .padding(.vertical, viewModel.verticalMargin)
                .overlay {
                    if viewModel.isSeparateLineDisplay {
                        HStack(spacing: .zero) {
                            Color.clear.frame(width: StatusView.hangingAvatarButtonDimension + StatusView.hangingAvatarButtonTrailingSpacing)
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                Color.clear.frame(height: 1)
                            }
                        }   // end HStack
                    }   // end if
                }   // end .overlay
            } else {
                VStack(spacing: .zero) {
                    HStack {
                        // avatar
                        avatarButton
                            .padding(.trailing, StatusView.hangingAvatarButtonTrailingSpacing)
                        Spacer()
                        // accessory view
                        accessoryView
                    }
                    // info
                    VStackLayout(alignment: .leading, spacing: .zero) {
                        headlineView
                        subheadlineView
                    }
                    .frame(alignment: .leading)
                }   // end HStack
                .padding(.vertical, viewModel.verticalMargin)
                .overlay {
                    if viewModel.isSeparateLineDisplay {
                        HStack(spacing: .zero) {
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                Color.clear.frame(height: 1)
                            }
                        }   // end HStack
                    }   // end if
                }   // end .overlay
            }
        }   // Group
    }
}

extension UserView {
    var allowsAvatarButtonHitTesting: Bool {
        switch viewModel.kind {
        case .account:          return false
        default:                return true
        }
    }
    
    var avatarButton: some View {
        Button {
            guard let user = viewModel.user?.asRecord else {
                assertionFailure()
                return
            }
            viewModel.delegate?.userView(viewModel, userAvatarButtonDidPressed: user)
        } label: {
            switch viewModel.kind {
            case .account:
                BadgeClipContainer {
                    avatarButtonContentView
                } badge: {
                    switch viewModel.platform {
                    case .none:
                        EmptyView()
                    case .twitter:
                        Image(uiImage: Asset.Badge.circleTwitter.image)
                    case .mastodon:
                        Image(uiImage: Asset.Badge.circleMastodon.image)
                    }
                }

            default:
                avatarButtonContentView
            }
        }
        .buttonStyle(.borderless)
        .allowsHitTesting(allowsAvatarButtonHitTesting)
    }
    
    var avatarButtonContentView: some View {
        Group {
            let dimension: CGFloat = StatusView.hangingAvatarButtonDimension
            KFImage(viewModel.avatarURL)
                .placeholder { progress in
                    Color(uiColor: .placeholderText)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: dimension, height: dimension)
                .clipShape(AvatarClipShape(avatarStyle: viewModel.avatarStyle))
                .animation(.easeInOut, value: viewModel.avatarStyle)
        }
    }
    
    var nameLabel: some View {
        LabelRepresentable(
            metaContent: viewModel.name,
            textStyle: .statusAuthorName,
            setupLabel: { label in
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var usernameLabel: some View {
        LabelRepresentable(
            metaContent: {
                guard !viewModel.username.isEmpty else { return PlaintextMetaContent(string: "") }
                return PlaintextMetaContent(string: "@" + viewModel.username)
            }(),
            textStyle: .statusAuthorUsername,
            setupLabel: { label in
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultLow - 100, for: .horizontal)
            }
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var menuView: some View {
        Menu {
            switch viewModel.kind {
            case .account:
                // open in new window
                if !viewModel.isMyself, UIApplication.shared.supportsMultipleScenes {
                    Button {
                        viewModel.delegate?.userView(viewModel, menuActionDidPressed: .openInNewWindowForAccount)
                    } label: {
                        Label {
                            Text("Open in new window")
                        } icon: {
                            Image(systemName: "macwindow.badge.plus")
                        }
                    }
                }
                // sign out
                Button(role: .destructive) {
                    viewModel.delegate?.userView(viewModel, menuActionDidPressed: .signOut)
                } label: {
                    Label {
                        Text(L10n.Common.Controls.Actions.signOut)
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.minus")
                    }
                }
            case .listMember:
                // remove
                Button(role: .destructive) {
                    viewModel.delegate?.userView(viewModel, menuActionDidPressed: .removeListMember)
                } label: {
                    Label {
                        Text(L10n.Common.Controls.Actions.remove)
                    } icon: {
                        Image(systemName: "minus.circle")
                    }
                }
            default:
                EmptyView()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .padding()
        }
    }
    
    var membershipButton: some View {
        Button {
            guard !viewModel.isListMemberCandidate else { return }
            guard let user = viewModel.user?.asRecord else { return }
            viewModel.delegate?.userView(viewModel, listMembershipButtonDidPressed: user)
        } label: {
            let tintColor = viewModel.isListMember ? UIColor.systemRed : Asset.Colors.hightLight.color
            let systemName = viewModel.isListMember ? "minus.circle" : "plus.circle"
            Image(systemName: systemName)
                .foregroundColor(Color(uiColor: tintColor))
                .padding()
                .opacity(viewModel.isListMemberCandidate ? 0 : 1)
                .overlay {
                    Group {
                        if viewModel.isListMemberCandidate {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }   // end overlay
        }
    }
    
    var followRequestActionView: some View {
        HStack(spacing: .zero) {
            Button {
                guard !viewModel.isFollowRequestBusy else { return }
                guard let user = viewModel.user?.asRecord else {
                    assertionFailure()
                    return
                }
                viewModel.delegate?.userView(viewModel, followReqeustButtonDidPressed: user, accept: true)
            } label: {
                Image(uiImage: Asset.Indices.checkmarkCircle.image.withRenderingMode(.alwaysTemplate))
                    .padding()
            }
            Button {
                guard !viewModel.isFollowRequestBusy else { return }
                guard let user = viewModel.user?.asRecord else {
                    assertionFailure()
                    return
                }
                viewModel.delegate?.userView(viewModel, followReqeustButtonDidPressed: user, accept: false)
            } label: {
                Image(uiImage: Asset.Indices.xmarkCircle.image.withRenderingMode(.alwaysTemplate))
                    .padding()
            }
            .tint(.secondary)
        }   // end HStack
        .opacity(viewModel.isFollowRequestBusy ? 0 : 1)
        .overlay(alignment: .trailing) {
            if viewModel.isFollowRequestBusy {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }
    
    var notificationBadgeCountView: some View {
        Group {
            let count = max(0, min(viewModel.notificationBadgeCount, 50))
            Image(systemName: "\(count).circle.fill")
        }
    }
    
    var checkmarkView: some View {
        Button {
            // do nothing
        } label: {
            let name = viewModel.isSelect ? "checkmark.circle.fill" : "circle"
            Image(systemName: name)
        }
        .buttonStyle(.borderless)
        .disabled(!viewModel.isSelectable)
    }
}
    
extension UserView {
    var headlineView: some View {
        Group {
            switch viewModel.kind {
            default:
                HStack(spacing: 6) {
                    nameLabel
                    if viewModel.protected {
                        Image(uiImage: Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate))
                            .resizable()
                            .frame(width: lockImageDimension, height: lockImageDimension)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }   // end Group
    }
    
    var subheadlineView: some View {
        Group {
            switch viewModel.kind {
            case .account:
                usernameLabel
            case .search:
                usernameLabel
            case .friend:
                usernameLabel
            case .history:
                usernameLabel
            case .notification:
                usernameLabel
            case .mentionPick:
                usernameLabel
            case .listMember:
                usernameLabel
            case .addListMember:
                usernameLabel
            case .settingAccountSection:
                usernameLabel
            case .plain:
                usernameLabel
            }
        }   // end Group
    }
    
    var accessoryView: some View {
        Group {
            switch viewModel.kind {
            case .account:
                HStack {
                    if viewModel.notificationBadgeCount > 0 {
                        notificationBadgeCountView
                    }
                    menuView
                }
            case .search:
                // TODO: follow button
                EmptyView()
            case .friend:
                EmptyView()
            case .history:
                EmptyView()
            case .notification:
                if viewModel.isFollowRequestActionDisplay {
                    followRequestActionView
                }
            case .mentionPick:
                checkmarkView
            case .listMember:
                if viewModel.isMyList {
                    menuView
                }
            case .addListMember:
                membershipButton
            case .settingAccountSection:
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.secondaryLabel))
            case .plain:
                EmptyView()
            }
        }   // end Group
    }
}

//public final class UserView: UIView {
//
//    let logger = Logger(subsystem: "UserView", category: "UI")
//
//    public static let avatarImageViewSize = CGSize(width: 44, height: 44)
//
//    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
//    var disposeBag = Set<AnyCancellable>()          // clear when reuse
//
//    weak var delegate: UserViewDelegate?
//
//    private(set) var style: Style?
//
//    public private(set) lazy var viewModel: ViewModel = {
//        let viewModel = ViewModel()
//        viewModel.bind(userView: self)
//        return viewModel
//    }()
//
//    // container
//    public let containerStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        return stackView
//    }()
//
//    public static var contentStackViewSpacing: CGFloat = 10
//    public let contentStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.spacing = UserView.contentStackViewSpacing
//        stackView.alignment = .center
//        return stackView
//    }()
//
//    public let infoContainerStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.distribution = .fillEqually
//        return stackView
//    }()
//
//    public let accessoryContainerView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.alignment = .firstBaseline
//        stackView.spacing = 8
//        return stackView
//    }()
//
//    // header
//    public let headerContainerView = UIView()
//    public let headerIconImageView = UIImageView()
//    public static var headerTextLabelStyle: TextStyle { .statusHeader }
//    public let headerTextLabel = MetaLabel(style: .statusHeader)
//
//    // avatar
//    public let authorProfileAvatarView: ProfileAvatarView = {
//        let profileAvatarView = ProfileAvatarView()
//        profileAvatarView.setup(dimension: .inline)
//        return profileAvatarView
//    }()
//
//    // name
//    public let nameLabel = MetaLabel(style: .userAuthorName)
//
//    // username
//    public let usernameLabel = PlainLabel(style: .userAuthorUsername)
//
//    // lock
//    public let lockImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .secondaryLabel
//        imageView.contentMode = .scaleAspectFill
//        imageView.image = Asset.ObjectTools.lockMiniInline.image.withRenderingMode(.alwaysTemplate)
//        return imageView
//    }()
//
//    // followerCount
//    public let followerCountLabel = PlainLabel(style: .userDescription)
//
//    // friendship control
//    public let friendshipButton: FriendshipButton = {
//        let button = FriendshipButton()
//        button.titleFont = UIFontMetrics(forTextStyle: .headline)
//            .scaledFont(for: UIFont.systemFont(ofSize: 13, weight: .semibold))
//        return button
//    }()
//
//    // checkmark control
//    public let checkmarkButton: UIButton = {
//        let button = UIButton()
//        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
//        button.tintColor = Asset.Colors.hightLight.color
//        return button
//    }()
//
//    // menu control
//    public let menuButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton()
//        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
//        button.tintColor = Asset.Colors.hightLight.color
//        return button
//    }()
//
//    // follow request
//    public let followRequestControlContainerView = UIStackView()
//
//    public private(set) lazy var acceptFollowRequestButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton()
//        button.setImage(Asset.Indices.checkmarkCircle.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.tintColor = Asset.Colors.hightLight.color    // FIXME: tint color
//        button.addTarget(self, action: #selector(UserView.acceptFollowRequestButtonDidPressed(_:)), for: .touchUpInside)
//        button.accessibilityLabel = L10n.Common.Notification.FollowRequestAction.approve
//        return button
//    }()
//
//    public private(set) lazy var rejectFollowRequestButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton()
//        button.setImage(Asset.Indices.xmarkCircle.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.tintColor = .secondaryLabel
//        button.addTarget(self, action: #selector(UserView.rejectFollowRequestButtonDidPressed(_:)), for: .touchUpInside)
//        button.accessibilityLabel = L10n.Common.Notification.FollowRequestAction.deny
//        return button
//    }()
//
//    // activity indicator
//    public let activityIndicatorView: UIActivityIndicatorView = {
//        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
//        activityIndicatorView.hidesWhenStopped = true
//        activityIndicatorView.startAnimating()
//        return activityIndicatorView
//    }()
//
//    // badge
//    public let badgeImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = .label
//        return imageView
//    }()
//
//    public func prepareForReuse() {
//        disposeBag.removeAll()
//        viewModel.prepareForReuse()
//        authorProfileAvatarView.avatarButton.avatarImageView.cancelTask()
//        Style.prepareForReuse(userView: self)
//    }
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//
//}
//
//extension UserView {
//    public enum MenuAction: Hashable {
//        case signOut
//        case remove
//    }
//
//}

//extension UserView {
//    private func _init() {
//        containerStackView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(containerStackView)
//        NSLayoutConstraint.activate([
//            containerStackView.topAnchor.constraint(equalTo: topAnchor),
//            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
//            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
//        ])
//
//        // container:: V - [ header container | content ]
//        containerStackView.addArrangedSubview(headerContainerView)
//        containerStackView.addArrangedSubview(contentStackView)
//
//        // content: H - [ user avatar | info container | accessory container ]
//        authorProfileAvatarView.translatesAutoresizingMaskIntoConstraints = false
//        contentStackView.addArrangedSubview(authorProfileAvatarView)
//        NSLayoutConstraint.activate([
//            authorProfileAvatarView.widthAnchor.constraint(equalToConstant: UserView.avatarImageViewSize.width).priority(.required - 1),
//            authorProfileAvatarView.heightAnchor.constraint(equalToConstant: UserView.avatarImageViewSize.height).priority(.required - 1),
//        ])
//        contentStackView.addArrangedSubview(infoContainerStackView)
//        contentStackView.addArrangedSubview(accessoryContainerView)
//
//        authorProfileAvatarView.isUserInteractionEnabled = false
//        nameLabel.isUserInteractionEnabled = false
//        usernameLabel.isUserInteractionEnabled = false
//        followerCountLabel.isUserInteractionEnabled = false
//
//        membershipButton.addTarget(self, action: #selector(UserView.membershipButtonDidPressed(_:)), for: .touchUpInside)
//
//        #if DEBUG
//        nameLabel.configure(content: PlaintextMetaContent(string: "Name"))
//        usernameLabel.text = "@username"
//        followerCountLabel.text = "1000 Followers"
//        #endif
//    }
//
//    public func setup(style: Style) {
//        guard self.style == nil else {
//            assertionFailure("Should only setup once")
//            return
//        }
//        self.style = style
//        style.layout(userView: self)
//        Style.prepareForReuse(userView: self)
//    }
//}
//
//extension UserView {
//
//    @objc private func membershipButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.userView(self, membershipButtonDidPressed: sender)
//    }
//
//    @objc private func acceptFollowRequestButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.userView(self, acceptFollowReqeustButtonDidPressed: sender)
//    }
//
//    @objc private func rejectFollowRequestButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.userView(self, rejectFollowReqeustButtonDidPressed: sender)
//    }
//
//}
//
//extension UserView {
//    public enum Style {
//        // headline: name | lock
//        // subheadline: username
//        // accessory: [ badge | menu ]
//        case account
//
//        // headline: name | lock | username
//        // subheadline: follower count
//        // accessory: follow button
//        case relationship
//
//        // headline: name | lock
//        // subheadline: username
//        // accessory: action button
//        case friendship
//
//        // header: notification
//        // headline: name | lock | username
//        // subheadline: follower count
//        // accessory: [ followRquest accept and reject button ]
//        case notification
//
//        // headline: name | lock
//        // subheadline: username
//        // accessory: checkmark button
//        case mentionPick
//
//        // headline: name | lock | username
//        // subheadline: follower count
//        // accessory: membership menu
//        case listMember
//
//        // headline: name | lock | username
//        // subheadline: follower count
//        // accessory: membership button
//        case addListMember
//
//        public func layout(userView: UserView) {
//            switch self {
//            case .account:          layoutAccount(userView: userView)
//            case .relationship:     layoutRelationship(userView: userView)
//            case .friendship:       layoutFriendship(userView: userView)
//            case .notification:     layoutNotification(userView: userView)
//            case .mentionPick:      layoutMentionPick(userView: userView)
//            case .listMember:       layoutListMember(userView: userView)
//            case .addListMember:    layoutAddListMember(userView: userView)
//            }
//        }
//
//        public static func prepareForReuse(userView: UserView) {
//            userView.headerContainerView.isHidden = true
//            userView.followRequestControlContainerView.isHidden = true
//        }
//    }
//}
//
//extension UserView.Style {
//
//    // headline: name | lock | username
//    // subheadline: follower count
//    private func layoutRelationshipBase(userView: UserView) {
//        let headlineStackView = UIStackView()
//        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
//        headlineStackView.axis = .horizontal
//        headlineStackView.spacing = 6
//        headlineStackView.addArrangedSubview(userView.nameLabel)
//        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        headlineStackView.addArrangedSubview(userView.lockImageView)
//        NSLayoutConstraint.activate([
//            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
//        ])
//        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        headlineStackView.addArrangedSubview(UIView())  // padding
//
//        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
//    }
//
//    // FIXME: update layout
//    func layoutAccount(userView: UserView) {
//        let headlineStackView = UIStackView()
//        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
//        headlineStackView.axis = .horizontal
//        headlineStackView.spacing = 6
//        headlineStackView.addArrangedSubview(userView.nameLabel)
//        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        headlineStackView.addArrangedSubview(userView.lockImageView)
//        NSLayoutConstraint.activate([
//            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
//        ])
//        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        headlineStackView.addArrangedSubview(UIView())  // padding
//
//        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
//
//        userView.accessoryContainerView.addArrangedSubview(userView.badgeImageView)
//        userView.accessoryContainerView.addArrangedSubview(userView.menuButton)
//        userView.badgeImageView.setContentHuggingPriority(.required - 2, for: .horizontal)
//        userView.badgeImageView.setContentCompressionResistancePriority(.required - 1, for: .vertical)
//        userView.menuButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//
//        userView.setNeedsLayout()
//    }
//
//    // FIXME: update layout
//    func layoutRelationship(userView: UserView) {
//        layoutRelationshipBase(userView: userView)
//
//        userView.friendshipButton.translatesAutoresizingMaskIntoConstraints = false
//        userView.accessoryContainerView.addArrangedSubview(userView.friendshipButton)
//        NSLayoutConstraint.activate([
////            userView.friendshipButton.heightAnchor.constraint(equalToConstant: 34).priority(.required - 1),
//            userView.friendshipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).priority(.required - 1),
//        ])
//        userView.friendshipButton.setContentHuggingPriority(.required - 10, for: .horizontal)
//        userView.friendshipButton.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//
//        userView.setNeedsLayout()
//    }
//
//    func layoutFriendship(userView: UserView) {
//        // headline
//        let headlineStackView = UIStackView()
//        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
//        headlineStackView.axis = .horizontal
//        headlineStackView.spacing = 6
//        headlineStackView.addArrangedSubview(userView.nameLabel)
//        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        headlineStackView.addArrangedSubview(userView.lockImageView)
//        NSLayoutConstraint.activate([
//            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
//        ])
//        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        headlineStackView.addArrangedSubview(userView.usernameLabel)
//        headlineStackView.addArrangedSubview(UIView())  // padding
//
//        // subheadline
//        userView.infoContainerStackView.addArrangedSubview(userView.followerCountLabel)
//
//        // TODO: menu
//
//        userView.setNeedsLayout()
//    }
//
//    func layoutNotification(userView: UserView) {
//        userView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
//        userView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        userView.headerContainerView.addSubview(userView.headerIconImageView)
//        userView.headerContainerView.addSubview(userView.headerTextLabel)
//        NSLayoutConstraint.activate([
//            userView.headerTextLabel.topAnchor.constraint(equalTo: userView.headerContainerView.topAnchor),
//            userView.headerTextLabel.bottomAnchor.constraint(equalTo: userView.headerContainerView.bottomAnchor),
//            userView.headerTextLabel.trailingAnchor.constraint(equalTo: userView.headerContainerView.trailingAnchor),
//            userView.headerIconImageView.centerYAnchor.constraint(equalTo: userView.headerTextLabel.centerYAnchor),
//            userView.headerIconImageView.heightAnchor.constraint(equalTo: userView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            userView.headerIconImageView.widthAnchor.constraint(equalTo: userView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            userView.headerTextLabel.leadingAnchor.constraint(equalTo: userView.headerIconImageView.trailingAnchor, constant: 4),
//            // align to author name below
//        ])
//        userView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        userView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        userView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//
//        layoutRelationshipBase(userView: userView)
//
//        // set header label align to author name
//        NSLayoutConstraint.activate([
//            userView.headerTextLabel.leadingAnchor.constraint(equalTo: userView.authorProfileAvatarView.trailingAnchor, constant: UserView.contentStackViewSpacing),
//        ])
//
//        // follow request button
//        userView.accessoryContainerView.addArrangedSubview(userView.followRequestControlContainerView)
//        userView.followRequestControlContainerView.axis = .horizontal
//        userView.followRequestControlContainerView.spacing = 20
//        userView.followRequestControlContainerView.isHidden = true
//
//        userView.followRequestControlContainerView.addArrangedSubview(userView.acceptFollowRequestButton)
//        userView.followRequestControlContainerView.addArrangedSubview(userView.rejectFollowRequestButton)
//        userView.acceptFollowRequestButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.acceptFollowRequestButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//        userView.rejectFollowRequestButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.rejectFollowRequestButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//
//        userView.accessoryContainerView.addArrangedSubview(userView.activityIndicatorView)
//        userView.activityIndicatorView.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.activityIndicatorView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//        userView.activityIndicatorView.isHidden = true
//
//        userView.setNeedsLayout()
//    }
//
//    func layoutMentionPick(userView: UserView) {
//        let headlineStackView = UIStackView()
//        userView.infoContainerStackView.addArrangedSubview(headlineStackView)
//        headlineStackView.axis = .horizontal
//        headlineStackView.spacing = 6
//        headlineStackView.addArrangedSubview(userView.nameLabel)
//        userView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        headlineStackView.addArrangedSubview(userView.lockImageView)
//        NSLayoutConstraint.activate([
//            userView.lockImageView.heightAnchor.constraint(equalTo: userView.nameLabel.heightAnchor).priority(.required - 10),
//        ])
//        userView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        userView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        headlineStackView.addArrangedSubview(UIView())  // padding
//
//
//        userView.infoContainerStackView.addArrangedSubview(userView.usernameLabel)
//
//        userView.accessoryContainerView.addArrangedSubview(userView.checkmarkButton)
//        userView.checkmarkButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.checkmarkButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//
//        userView.accessoryContainerView.addArrangedSubview(userView.activityIndicatorView)
//        userView.activityIndicatorView.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.activityIndicatorView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//        userView.activityIndicatorView.isHidden = true
//
//        userView.setNeedsLayout()
//    }
//
//    func layoutAddListMember(userView: UserView) {
//        layoutRelationshipBase(userView: userView)
//
//        userView.membershipButton.translatesAutoresizingMaskIntoConstraints = false
//        userView.accessoryContainerView.addArrangedSubview(userView.membershipButton)
//        NSLayoutConstraint.activate([
//            userView.membershipButton.widthAnchor.constraint(equalToConstant: 44),
//            userView.membershipButton.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1),
//        ])
//        userView.membershipButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.membershipButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//
//        userView.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
//        userView.accessoryContainerView.addSubview(userView.activityIndicatorView)
//        NSLayoutConstraint.activate([
//            userView.activityIndicatorView.centerXAnchor.constraint(equalTo: userView.membershipButton.centerXAnchor),
//            userView.activityIndicatorView.centerYAnchor.constraint(equalTo: userView.membershipButton.centerYAnchor),
//        ])
//        userView.activityIndicatorView.isHidden = true
//    }
//
//    func layoutListMember(userView: UserView) {
//        layoutRelationshipBase(userView: userView)
//
//        userView.menuButton.translatesAutoresizingMaskIntoConstraints = false
//        userView.accessoryContainerView.addArrangedSubview(userView.menuButton)
//        userView.menuButton.setContentHuggingPriority(.required - 1, for: .horizontal)
//        userView.menuButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//    }
//
//}
//
//extension UserView {
//    public func setHeaderDisplay() {
//        headerContainerView.isHidden = false
//    }
//
//    public func setFollowRequestControlDisplay() {
//        followRequestControlContainerView.isHidden = false
//    }
//}


#if DEBUG
import CoreData
import CoreDataStack

struct UserView_Preview: PreviewProvider {
    
    static var kinds: [UserView.ViewModel.Kind] = [
        .account,
        .search,
        .friend,
        .history,
        // .notification,
        .mentionPick,
        // .listMember,
        // .addListMember,
        .settingAccountSection,
        .plain
    ]
    
    static var previews: some View {
        List {
            ForEach(kinds, id: \.self) { kind in
                Section(content: {
                    UserView(viewModel: .init(kind: kind))
                        .padding(.horizontal)
                }, header: {
                    Text("\(String(describing: kind).localizedCapitalized)")
                })
                .textCase(nil)
            }
        }
    }
}
#endif
