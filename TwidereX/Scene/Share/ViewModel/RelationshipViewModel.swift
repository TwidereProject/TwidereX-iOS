//
//  RelationshipViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import Combine
import CoreDataStack

enum Relationship: Int, CaseIterable {
    case followingBy
    case none       // set hide from UI
    case follow
    case request
    case pending
    case following
    case muting
    case blocked
    case blocking
    case suspended
    
    var option: RelationshipOptionSet {
        return RelationshipOptionSet(rawValue: 1 << rawValue)
    }
    
    var title: String {
        switch self {
        case .followingBy: return L10n.Common.Controls.Friendship.followsYou
        case .none: return " "
        case .follow: return L10n.Common.Controls.Friendship.Actions.follow
        case .request: return L10n.Common.Controls.Friendship.Actions.request
        case .pending: return L10n.Common.Controls.Friendship.Actions.pending
        case .following: return L10n.Common.Controls.Friendship.Actions.following
        case .muting: return L10n.Common.Controls.Friendship.Actions.unmute    // muting
        case .blocked: return L10n.Common.Controls.Friendship.Actions.follow   // blocked by user, button should disabled
        case .blocking: return L10n.Common.Controls.Friendship.Actions.blocked
        case .suspended: return L10n.Common.Controls.Friendship.Actions.follow
        }
    }
    
}

// construct option set on the enum for safe iterator
struct RelationshipOptionSet: OptionSet {
    let rawValue: Int
    
    static let followingBy = Relationship.followingBy.option
    static let none = Relationship.none.option
    static let follow = Relationship.follow.option
    static let request = Relationship.request.option
    static let pending = Relationship.pending.option
    static let following = Relationship.following.option
    static let muting = Relationship.muting.option
    static let blocked = Relationship.blocked.option
    static let blocking = Relationship.blocking.option
    static let suspended = Relationship.suspended.option
    
    
    func relationship(except optionSet: RelationshipOptionSet) -> Relationship? {
        let set = subtracting(optionSet)
        for action in Relationship.allCases.reversed() where set.contains(action.option) {
            return action
        }
        
        return nil
    }
}

final class RelationshipViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    var userObserver: AnyCancellable?
    var meObserver: AnyCancellable?
    
    // input
    @Published var user: UserObject?
    @Published var me: UserObject?
    let relationshipUpdatePublisher = CurrentValueSubject<Void, Never>(Void())  // needs initial event
    
    // output
    @Published var isMyself = false
    @Published var optionSet: RelationshipOptionSet?
    
    @Published var isFollowing = false
    @Published var isFollowingBy = false
    @Published var isMuting = false
    @Published var isBlocking = false
    @Published var isBlockingBy = false
    
    init() {
        Publishers.CombineLatest3(
            $user,
            $me,
            relationshipUpdatePublisher
        )
        .sink { [weak self] user, me, _ in
            guard let self = self else { return }
            self.update(user: user, me: me)
            
            // do not modify object to prevent infinity loop
            self.userObserver = RelationshipViewModel.createObjectChangePublisher(user: user)?
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.relationshipUpdatePublisher.send()
                }
                
            self.meObserver = RelationshipViewModel.createObjectChangePublisher(user: me)?
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.relationshipUpdatePublisher.send()
                }
        }
        .store(in: &disposeBag)
    }
    
}

extension RelationshipViewModel {
    
    static func createObjectChangePublisher(user: UserObject?) -> AnyPublisher<Void, Never>? {
        guard let user = user else { return nil }
        switch user {
        case .twitter(let object):
            return ManagedObjectObserver
                .observe(object: object)
                .map { _ in Void() }
                .catch { error in
                    return Just(Void())
                }
                .eraseToAnyPublisher()

        case .mastodon(let object):
            return ManagedObjectObserver
                .observe(object: object)
                .map { _ in Void() }
                .catch { error in
                    return Just(Void())
                }
                .eraseToAnyPublisher()
        }
    }
    
}

extension RelationshipViewModel {
    private func update(user: UserObject?, me: UserObject?) {
        let isMyself: Bool
        let isProtected: Bool
        let isFollowing: Bool
        let isPending: Bool
        let isFollowingBy: Bool
        let isMuting: Bool
        let isBlocking: Bool
        let isBlockingBy: Bool
        var optionSet: RelationshipOptionSet = [.follow]
        
        switch (user, me) {
        case (.twitter(let user), .twitter(let me)):
            isMyself = user.id == me.id
            guard !isMyself else {
                reset()
                self.isMyself = true
                self.optionSet = [.none]
                return
            }
            
            isProtected = user.protected
            isFollowing = user.followingBy.contains(me)
            isPending = user.followRequestSentFrom.contains(me)
            isFollowingBy = me.followingBy.contains(user)
            isMuting = user.mutingBy.contains(me)
            isBlocking = user.blockingBy.contains(me)
            isBlockingBy = me.blockingBy.contains(user)
            
        case (.mastodon(let user), .mastodon(let me)):
            isMyself = user.id == me.id && user.domain == me.domain
            guard !isMyself else {
                reset()
                self.isMyself = true
                self.optionSet = [.none]
                return
            }
                
            isProtected = user.locked
            isFollowing = user.followingBy.contains(me)
            isPending = user.followRequestSentFrom.contains(me)
            isFollowingBy = me.followingBy.contains(user)
            isMuting = user.mutingBy.contains(me)
            isBlocking = user.blockingBy.contains(me)
            isBlockingBy = me.blockingBy.contains(user)
            
        default:
            self.reset()
            return
        }
        
        self.isMyself = isMyself
        
        if isProtected {
            optionSet.insert(.request)
        }
        
        if isFollowing {
            optionSet.insert(.following)
        }
        
        if isPending {
            optionSet.insert(.pending)
        }
        
        if isFollowingBy {
            optionSet.insert(.followingBy)
        }
        self.isFollowingBy = isFollowingBy
        
        if isMuting {
            optionSet.insert(.muting)
        }
        self.isMuting = isMuting
        
        if isBlocking {
            optionSet.insert(.blocking)
        }
        self.isBlocking = isBlocking
        
        if isBlockingBy {
            optionSet.insert(.blocked)
        }
        self.isBlockingBy = isBlockingBy
        
        self.optionSet = optionSet
    }
    
    private func reset() {
        isMyself = false
        optionSet = nil
        isFollowing = false
        isFollowingBy = false
        isMuting = false
        isBlocking = false
        isBlockingBy = false
    }
}
