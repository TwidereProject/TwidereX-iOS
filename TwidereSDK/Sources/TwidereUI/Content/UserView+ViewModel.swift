//
//  UserView+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack
import TwidereCore
import TwidereAsset
import Meta
import MastodonSDK

extension UserView {
    public final class ViewModel: ObservableObject {
        
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()

        let relationshipViewModel = RelationshipViewModel()
        
        // input
        public let user: UserObject?
        public let authContext: AuthContext?
        public let kind: Kind
        public weak var delegate: UserViewDelegate?
        
        public private(set) var notification: NotificationObject?
        
        // output
        
        // user
        @Published public var avatarURL: URL?
        @Published public var avatarStyle = UserDefaults.shared.avatarStyle
        
        @Published public var name: MetaContent = PlaintextMetaContent(string: "")
        @Published public var username: String = ""
        
        @Published public var platform: Platform = .none
        
        @Published public var isMyself: Bool = false
        @Published public var protected: Bool = false
        
        // TODO: verified | bot

        // follow request
        @Published public var isFollowRequestActionDisplay = false
        @Published public var isFollowRequestBusy = false
        
        // follow
        @Published public var followButtonViewModel: FollowButton.ViewModel?

        public var listMembershipViewModel: ListMembershipViewModel?
        @Published public var listOwnerUserIdentifier: UserIdentifier? = nil
        @Published public var isListMember = false
        @Published public var isListMemberCandidate = false       // a.k.a isBusy
        @Published public var isMyList = false

        // notification count
        @Published public var notificationBadgeCount: Int = 0

        @Published public var isSelectable: Bool = true
        @Published public var isSelect: Bool = false
        
        private init(
            object user: UserObject?,
            authContext: AuthContext?,
            kind: Kind,
            delegate: UserViewDelegate?
        ) {
            self.user = user
            self.authContext = authContext
            self.kind = kind
            self.delegate = delegate
            // end init
            
            switch kind {
            case .notification(let notification):
                self.notification = notification
                
            case .listMember(let listMembershipViewModel), .addListMember(let listMembershipViewModel):
                if let listMembershipViewModel = listMembershipViewModel,
                   let userRecord = user?.asRecord
                {
                    self.listMembershipViewModel = listMembershipViewModel
                    listMembershipViewModel.$ownerUserIdentifier
                        .assign(to: \.listOwnerUserIdentifier, on: self)
                        .store(in: &disposeBag)
                    listMembershipViewModel.$members
                        .map { members in members.contains(userRecord) }
                        .assign(to: \.isListMember, on: self)
                        .store(in: &disposeBag)
                    listMembershipViewModel.$workingMembers
                        .map { members in members.contains(userRecord) }
                        .assign(to: \.isListMemberCandidate, on: self)
                        .store(in: &disposeBag)
                }
            default:
                break
            }
            
            // isMyself
            isMyself = {
                guard let authContext = self.authContext,
                      let user = self.user
                else { return false }
                return authContext.authenticationContext.userIdentifier == user.userIdentifer
            }()
            
            // follow request
            switch notification {
            case .twitter:
                break
            case .mastodon(let notification):
                self.isFollowRequestActionDisplay = notification.notificationType == .followRequest
                notification.publisher(for: \.isFollowRequestBusy)
                    .assign(to: &$isFollowRequestBusy)
            default:
                break
            }
            
            switch kind {
            case .search:       // follow
                if let authContext = authContext, let user = user {
                    self.followButtonViewModel = .init(user: user, authContext: authContext)
                }
            default:
                break
            }
            
            // avatar style
            UserDefaults.shared.publisher(for: \.avatarStyle)
                .assign(to: &$avatarStyle)
            
            // isMyList
            $listOwnerUserIdentifier
                .map { userIdentifier -> Bool in
                    guard let authenticationContext = authContext?.authenticationContext else { return false }
                    guard let userIdentifier = userIdentifier else { return false }
                    return authenticationContext.userIdentifier == userIdentifier
                }
                .assign(to: &$isMyList)
            
            // notification badge count
            notificationBadgeCount = {
                switch authContext?.authenticationContext {
                case .twitter:
                    return 0
                case .mastodon(let authenticationContext):
                    let accessToken = authenticationContext.authorization.accessToken
                    let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                    return count
                case nil:
                    return 0
                }
            }()
        }   // end init
    }
}

extension UserView.ViewModel {
    public enum Kind: Hashable {
        // headline: name | lock
        // subheadline: username
        // accessory: [ badge | menu ]
        case account
        
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: follow button
        case search
        
        // headline: name | lock
        // subheadline: username
        // accessory: none
        case friend
        
        // headline: name | lock
        // subheadline: username
        // accessory: none
        case history
        
        // header: notification
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: [ followRquest accept and reject button ]
        case notification(NotificationObject)
        
        // headline: name | lock
        // subheadline: username
        // accessory: checkmark button
        case mentionPick
        
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: membership menu (isMyList)
        // menuActions: [ remove ]
        case listMember(ListMembershipViewModel?)
        
        // headline: name | lock | username
        // subheadline: follower count
        // accessory: membership button
        case addListMember(ListMembershipViewModel?)
        
        // headline: name | lock
        // subheadline: username
        // accessory: disclosureIndicator
        case settingAccountSection
        
        // headline: name | lock
        // subheadline: username
        // accessory: none
        case plain
    }
    
    public enum AvatarBadge {
        case none
        case platform
        case user   // verified | bot
    }
    
    public enum MenuAction: Hashable {
        case openInNewWindowForAccount
        case signOut
        case removeListMember
    }
}

extension UserView.ViewModel {
    var verticalMargin: CGFloat {
        switch kind {
        case .notification:     return .zero
        default:                return 12.0
        }
    }
    
    var isSeparateLineDisplay: Bool {
        switch kind {
        case .notification:             return false
        case .settingAccountSection:    return false
        case .plain:                    return false
        case .mentionPick:              return false
        default:                        return true
        }
    }
}
//extension UserView.ViewModel {
//    public func bind(userView: UserView) {
//        // avatar
//        $avatarImageURL
//            .sink { url in
//                let configuration = AvatarImageView.Configuration(url: url)
//                userView.authorProfileAvatarView.avatarButton.avatarImageView.configure(configuration: configuration)
//            }
//            .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            $avatarBadge,
//            $platform
//        )
//        .sink { avatarBadge, platform in
//            switch avatarBadge {
//            case .none:
//                userView.authorProfileAvatarView.badge = .none
//            case .platform:
//                userView.authorProfileAvatarView.badge = {
//                    switch platform {
//                    case .none:         return .none
//                    case .twitter:      return .circle(.twitter)
//                    case .mastodon:     return .circle(.mastodon)
//                    }
//                }()
//            case .user:
//                userView.authorProfileAvatarView.badge = .none
//            }
//        }
//        .store(in: &disposeBag)
//        // badge
//        // TODO:
//        // header
//        $header
//            .sink { header in
//                switch header {
//                case .none:
//                    return
//                case .notification(let info):
//                    userView.headerIconImageView.image = info.iconImage
//                    userView.headerIconImageView.tintColor = info.iconImageTintColor
//                    userView.headerTextLabel.setupAttributes(style: UserView.headerTextLabelStyle)
//                    userView.headerTextLabel.configure(content: info.textMetaContent)
//                    userView.setHeaderDisplay()
//                }
//            }
//            .store(in: &disposeBag)
//        // name
//        $name
//            .sink { content in
//                guard let content = content else {
//                    userView.nameLabel.reset()
//                    return
//                }
//                userView.nameLabel.configure(content: content)
//            }
//            .store(in: &disposeBag)
//        // username
//        $username
//            .map { username in
//                return username.flatMap { "@\($0)" } ?? " "
//            }
//            .assign(to: \.text, on: userView.usernameLabel)
//            .store(in: &disposeBag)
//        // protected
//        $protected
//            .map { !$0 }
//            .assign(to: \.isHidden, on: userView.lockImageView)
//            .store(in: &disposeBag)
//        // follower count
//        $followerCount
//            .sink { followerCount in
//                let count = followerCount.flatMap { String($0) } ?? "-"
//                userView.followerCountLabel.text = L10n.Common.Controls.ProfileDashboard.followers + ": " + count
//            }
//            .store(in: &disposeBag)
//        // relationship
//        relationshipViewModel.$optionSet
//            .map { $0?.relationship(except: [.muting]) }
//            .sink { relationship in
//                guard let relationship = relationship else { return }
//                userView.friendshipButton.configure(relationship: relationship)
//                userView.friendshipButton.isHidden = relationship == .isMyself
//            }
//            .store(in: &disposeBag)
//
//        // accessory
//
//        case .notification:
//            $isFollowRequestBusy
//                .sink { isFollowRequestBusy in
//                    userView.acceptFollowRequestButton.isHidden = isFollowRequestBusy
//                    userView.rejectFollowRequestButton.isHidden = isFollowRequestBusy
//                    userView.activityIndicatorView.isHidden = !isFollowRequestBusy
//                    userView.activityIndicatorView.startAnimating()
//                }
//                .store(in: &disposeBag)
//
//        default:
//            userView.menuButton.showsMenuAsPrimaryAction = true
//            userView.menuButton.menu = nil
//        }
//    }
//    
//}

extension UserView.ViewModel {
    public convenience init?(
        user: UserObject?,
        authContext: AuthContext?,
        kind: Kind,
        delegate: UserViewDelegate?
    ) {
        switch user {
        case .twitter(let object):
            self.init(
                user: object,
                authContext: authContext,
                kind: kind,
                delegate: delegate
            )
        case .mastodon(let object):
            self.init(
                user: object,
                authContext: authContext,
                kind: kind,
                delegate: delegate
            )
        default:
            return nil
        }
        // end init
    }
}

extension UserView.ViewModel {
    public convenience init(
        user: TwitterUser,
        authContext: AuthContext?,
        kind: Kind,
        delegate: UserViewDelegate?
    ) {
        self.init(
            object: .twitter(object: user),
            authContext: authContext,
            kind: kind,
            delegate: delegate
        )
        // end init
        
        // user
        platform = .twitter
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: &$avatarURL)
        user.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: &$name)
        user.publisher(for: \.username)
            .assign(to: &$username)
        user.publisher(for: \.protected)
            .assign(to: &$protected)
    }
    
    public convenience init(
        user: MastodonUser,
        authContext: AuthContext?,
        kind: Kind,
        delegate: UserViewDelegate?
    ) {
        self.init(
            object: .mastodon(object: user),
            authContext: authContext,
            kind: kind,
            delegate: delegate
        )
        // end init
        
        // user
        platform = .mastodon
        user.publisher(for: \.avatar)
            .compactMap { $0.flatMap { URL(string: $0) } }
            .assign(to: &$avatarURL)
        user.publisher(for: \.displayName)
            .compactMap { _ in user.nameMetaContent }
            .assign(to: &$name)
        user.publisher(for: \.username)
            .map { _ in user.acctWithDomain }
            .assign(to: &$username)
        user.publisher(for: \.locked)
            .assign(to: &$protected)
    }
}

extension UserView.ViewModel {
    public convenience init(
        item: MentionPickViewModel.Item,
        delegate: UserViewDelegate?
    ) {
        self.init(
            object: nil,
            authContext: nil,
            kind: .mentionPick,
            delegate: delegate
        )
        // end init

        // user
        switch item {
        case .twitterUser(let username, let attribute):
            self.avatarURL = attribute.avatarImageURL
            self.name = PlaintextMetaContent(string: attribute.name ?? "")
            self.username = username
            self.isSelectable = !attribute.disabled
            self.isSelect = attribute.selected
        }   // switch
    }
}

#if DEBUG
extension UserView.ViewModel {
    public convenience init(kind: Kind) {
        self.init(
            object: nil,
            authContext: nil,
            kind: kind,
            delegate: nil
        )
        // end init
        
        avatarURL = URL(string: "https://pbs.twimg.com/profile_images/1445764922474827784/W2zEPN7U_400x400.jpg")
        name = PlaintextMetaContent(string: "Name")
        username = "username"
        platform = .twitter
        notificationBadgeCount = 10
        protected = true
    }
}
#endif
