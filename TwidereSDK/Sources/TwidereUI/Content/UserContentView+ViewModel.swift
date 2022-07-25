//
//  UserContentView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import SwiftUI
import TwidereCore
import Meta

extension UserContentView {
    public class ViewModel: ObservableObject {

        // input
        public let user: UserObject
        public let accessoryType: AccessoryType
        
        // output
        @Published public var platform: Platform = .none

        @Published public var name: MetaContent = PlaintextMetaContent(string: " ")
        @Published public var username: MetaContent = PlaintextMetaContent(string: " ")
        @Published public var acct: MetaContent = PlaintextMetaContent(string: " ")
        @Published public var avatarImageURL: URL?
        
        @Published public var protected: Bool = false

        public init(
            user: UserObject,
            accessoryType: AccessoryType
        ) {
            self.user = user
            self.accessoryType = accessoryType
            // end init
            
            configure()
        }
    }
}

extension UserContentView.ViewModel {

    public enum AccessoryType {
        case none
        case disclosureIndicator
    }
    
}

extension UserContentView.ViewModel {
    
    func configure() {
        assert(Thread.isMainThread)
        
        switch user {
        case .twitter(let user):
            configure(user: user)
        case .mastodon(let user):
            configure(user: user)
        }
    }
    
}

extension UserContentView.ViewModel {
    private func configure(user: TwitterUser) {
        // platform
        platform = .twitter
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: &$avatarImageURL)
        // author name
        user.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: &$name)
        // author username
        user.publisher(for: \.username)
            .map { PlaintextMetaContent(string: "@" + $0) }
            .assign(to: &$username)
        // acct
        user.publisher(for: \.username)
            .map { PlaintextMetaContent(string: "@" + $0) }
            .assign(to: &$acct)
        // protected
        user.publisher(for: \.protected)
            .assign(to: &$protected)
    }
}

extension UserContentView.ViewModel {
    private func configure(user: MastodonUser) {
        // platform
        platform = .mastodon
        // avatar
        Publishers.CombineLatest3(
            UserDefaults.shared.publisher(for: \.preferredStaticAvatar),
            user.publisher(for: \.avatar),
            user.publisher(for: \.avatarStatic)
        )
        .map { preferredStaticAvatar, avatar, avatarStatic in
            let string = preferredStaticAvatar ? (avatarStatic ?? avatar) : avatar
            return string.flatMap { URL(string: $0) }
        }
        .assign(to: &$avatarImageURL)
        // author name
        Publishers.CombineLatest(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis)
        )
        .map { name, _ -> MetaContent in
            user.nameMetaContent ?? PlaintextMetaContent(string: name)
        }
        .assign(to: &$name)
        // author username
        user.publisher(for: \.acct)
            .map { PlaintextMetaContent(string: "@" + $0) }
            .assign(to: &$username)
        // acct
        user.publisher(for: \.acct)
            .map { _ in PlaintextMetaContent(string: "@" + user.acctWithDomain) }
            .assign(to: &$acct)
        // protected
        user.publisher(for: \.locked)
            .assign(to: &$protected)
    }
}
