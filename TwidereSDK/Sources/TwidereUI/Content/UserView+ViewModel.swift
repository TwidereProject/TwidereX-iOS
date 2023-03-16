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
        
        @Published public var platform: Platform = .none
        @Published public var authenticationContext: AuthenticationContext?       // me
        @Published public var userAuthenticationContext: AuthenticationContext?

        @Published public var header: Header = .none
        
        @Published public var userIdentifier: UserIdentifier? = nil
        @Published public var avatarImageURL: URL?
        @Published public var avatarBadge: AvatarBadge = .none
        // TODO: verified | bot
        
        @Published public var name: MetaContent? = PlaintextMetaContent(string: " ")
        @Published public var username: String?
        
        @Published public var protected: Bool = false
        
        @Published public var followerCount: Int?
        
        @Published public var isFollowRequestBusy = false
        
        public var listMembershipViewModel: ListMembershipViewModel?
        @Published public var listOwnerUserIdentifier: UserIdentifier? = nil
        @Published public var isListMember = false
        @Published public var isListMemberCandidate = false       // a.k.a isBusy
        @Published public var isMyList = false
        
        @Published public var badgeCount: Int = 0
        
        public enum Header {
            case none
            case notification(info: NotificationHeaderInfo)
        }
        
        public enum AvatarBadge {
            case none
            case platform
            case user   // verified | bot
        }
        
        func prepareForReuse() {
            avatarImageURL = nil
            isFollowRequestBusy = false
        }
        
        init() {
            // isMyList
            Publishers.CombineLatest(
                $authenticationContext,
                $listOwnerUserIdentifier
            )
            .map { authenticationContext, userIdentifier -> Bool in
                guard let authenticationContext = authenticationContext else { return false }
                guard let userIdentifier = userIdentifier else { return false }
                return authenticationContext.userIdentifier == userIdentifier
            }
            .assign(to: &$isMyList)
            // badge count
            $userAuthenticationContext
                .map { authenticationContext -> Int in
                    switch authenticationContext {
                    case .twitter:
                        return 0
                    case .mastodon(let authenticationContext):
                        let accessToken = authenticationContext.authorization.accessToken
                        let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                        return count
                    case .none:
                        return 0
                    }
                }
                .assign(to: &$badgeCount)
        }
    }
}

extension UserView.ViewModel {
    public func bind(userView: UserView) {
        // avatar
        $avatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                userView.authorProfileAvatarView.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest(
            $avatarBadge,
            $platform
        )
        .sink { avatarBadge, platform in
            switch avatarBadge {
            case .none:
                userView.authorProfileAvatarView.badge = .none
            case .platform:
                userView.authorProfileAvatarView.badge = {
                    switch platform {
                    case .none:         return .none
                    case .twitter:      return .circle(.twitter)
                    case .mastodon:     return .circle(.mastodon)
                    }
                }()
            case .user:
                userView.authorProfileAvatarView.badge = .none
            }
        }
        .store(in: &disposeBag)
        // badge
        // TODO:
        // header
        $header
            .sink { header in
                switch header {
                case .none:
                    return
                case .notification(let info):
                    userView.headerIconImageView.image = info.iconImage
                    userView.headerIconImageView.tintColor = info.iconImageTintColor
                    userView.headerTextLabel.setupAttributes(style: UserView.headerTextLabelStyle)
                    userView.headerTextLabel.configure(content: info.textMetaContent)
                    userView.setHeaderDisplay()
                }
            }
            .store(in: &disposeBag)
        // name
        $name
            .sink { content in
                guard let content = content else {
                    userView.nameLabel.reset()
                    return
                }
                userView.nameLabel.configure(content: content)
            }
            .store(in: &disposeBag)
        // username
        $username
            .map { username in
                return username.flatMap { "@\($0)" } ?? " "
            }
            .assign(to: \.text, on: userView.usernameLabel)
            .store(in: &disposeBag)
        // protected
        $protected
            .map { !$0 }
            .assign(to: \.isHidden, on: userView.lockImageView)
            .store(in: &disposeBag)
        // follower count
        $followerCount
            .sink { followerCount in
                let count = followerCount.flatMap { String($0) } ?? "-"
                userView.followerCountLabel.text = L10n.Common.Controls.ProfileDashboard.followers + ": " + count
            }
            .store(in: &disposeBag)
        // relationship
        relationshipViewModel.$optionSet
            .map { $0?.relationship(except: [.muting]) }
            .sink { relationship in
                guard let relationship = relationship else { return }
                userView.friendshipButton.configure(relationship: relationship)
                userView.friendshipButton.isHidden = relationship == .isMyself
            }
            .store(in: &disposeBag)

        // accessory
        switch userView.style {
        case .account:
            $badgeCount
                .sink { count in
                    let count = max(0, min(count, 50))
                    userView.badgeImageView.image = UIImage(systemName: "\(count).circle.fill")?.withRenderingMode(.alwaysTemplate)
                    userView.badgeImageView.isHidden = count == 0
                }
                .store(in: &disposeBag)
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = {
                let children = [
                    UIAction(
                        title: L10n.Common.Controls.Actions.signOut,
                        image: UIImage(systemName: "person.crop.circle.badge.minus"),
                        attributes: .destructive,
                        state: .off
                    ) { [weak userView] _ in
                        guard let userView = userView else { return }
                        userView.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): sign out user…")
                        userView.delegate?.userView(userView, menuActionDidPressed: .signOut, menuButton: userView.menuButton)
                    }
                ]
                return UIMenu(title: "", image: nil, options: [], children: children)
            }()
            
        case .notification:
            $isFollowRequestBusy
                .sink { isFollowRequestBusy in
                    userView.acceptFollowRequestButton.isHidden = isFollowRequestBusy
                    userView.rejectFollowRequestButton.isHidden = isFollowRequestBusy
                    userView.activityIndicatorView.isHidden = !isFollowRequestBusy
                    userView.activityIndicatorView.startAnimating()
                }
                .store(in: &disposeBag)
                
        case .listMember:
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = {
                let children = [
                    UIAction(
                        title: L10n.Common.Controls.Actions.remove,
                        image: UIImage(systemName: "minus.circle"),
                        attributes: .destructive,
                        state: .off
                    ) { [weak userView] _ in
                        guard let userView = userView else { return }
                        userView.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): remove user…")
                        userView.delegate?.userView(userView, menuActionDidPressed: .remove, menuButton: userView.menuButton)
                    }
                ]
                return UIMenu(title: "", image: nil, options: [], children: children)
            }()
            $isMyList
                .map { !$0 }
                .assign(to: \.isHidden, on: userView.menuButton)
                .store(in: &disposeBag)
        case .addListMember:
            Publishers.CombineLatest(
                $isListMember,
                $isListMemberCandidate
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak userView] isMember, isMemberCandidate in
                guard let userView = userView else { return }
                let image = isMember ? UIImage(systemName: "minus.circle") : UIImage(systemName: "plus.circle")
                let tintColor = isMember ? UIColor.systemRed : Asset.Colors.hightLight.color
                userView.membershipButton.setImage(image, for: .normal)
                userView.membershipButton.tintColor = tintColor
                
                userView.membershipButton.alpha = isMemberCandidate ? 0 : 1
                userView.activityIndicatorView.isHidden = !isMemberCandidate
                userView.activityIndicatorView.startAnimating()
            }
            .store(in: &disposeBag)
                
        default:
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = nil
        }
    }
    
}
