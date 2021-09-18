//
//  FriendshipButton.swift
//  FriendshipButton
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class FriendshipButton: UIButton {
    
    static let height: CGFloat = 32
    
    private(set) var relationship: Relationship = .follow

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension FriendshipButton {
    private func _init() {
        configure(relationship: relationship)
    }
    
    override func updateConfiguration() {
        super.updateConfiguration()
        
        configure(relationship: relationship)
    }
    
    func configure(relationship: Relationship) {
        self.relationship = relationship
        
        var configuration = UIButton.Configuration.plain()
        configuration.cornerStyle = .capsule    // why capsule
        configuration.title = relationship.title
        configuration.background = background(for: relationship)
        self.configuration = configuration
    }
    
}

extension FriendshipButton {

    private func background(for relationship: Relationship) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        let alpha: CGFloat = isHighlighted ? 0.5 : 1.0
        
        switch relationship {
        case .none:
            break
        case .follow, .request:
            background.backgroundColor = .clear
            background.strokeColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        case .pending, .following:
            background.backgroundColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        case .blocked, .blocking, .suspended:
            background.backgroundColor = Asset.Colors.Tint.pink.color.withAlphaComponent(alpha)
            background.strokeColor = Asset.Colors.Tint.pink.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        }
        return background
    }

}

enum Relationship: Int, CaseIterable {
    case none       // set hide from UI
    case follow
    case request
    case pending
    case following
    case blocked
    case blocking
    case suspended
    
    var option: RelationshipOptionSet {
        return RelationshipOptionSet(rawValue: 1 << rawValue)
    }
    
    var title: String {
        switch self {
        case .none: return " "
        case .follow: return L10n.Common.Controls.Friendship.Actions.follow
        case .request: return L10n.Common.Controls.Friendship.Actions.request
        case .pending: return L10n.Common.Controls.Friendship.Actions.pending
        case .following: return L10n.Common.Controls.Friendship.Actions.following
        case .blocked: return L10n.Common.Controls.Friendship.Actions.follow   // blocked by user, button should disabled
        case .blocking: return L10n.Common.Controls.Friendship.Actions.blocked
        case .suspended: return L10n.Common.Controls.Friendship.Actions.follow
        }
    }
    
}

// construct option set on the enum for safe iterator
struct RelationshipOptionSet: OptionSet {
    let rawValue: Int
    
    static let none = Relationship.none.option
    static let follow = Relationship.follow.option
    static let request = Relationship.request.option
    static let pending = Relationship.pending.option
    static let following = Relationship.following.option
    static let blocked = Relationship.blocked.option
    static let blocking = Relationship.blocking.option
    static let suspended = Relationship.suspended.option
    
    
    func highestPriorityAction(except: RelationshipOptionSet) -> Relationship? {
        let set = subtracting(except)
        for action in Relationship.allCases.reversed() where set.contains(action.option) {
            return action
        }
        
        return nil
    }
//
//    var backgroundColor: UIColor {
//        guard let highPriorityAction = self.highPriorityAction(except: []) else {
//            assertionFailure()
//            return Asset.Colors.brandBlue.color
//        }
//        switch highPriorityAction {
//        case .none: return Asset.Colors.brandBlue.color
//        case .follow: return Asset.Colors.brandBlue.color
//        case .request: return Asset.Colors.brandBlue.color
//        case .pending: return Asset.Colors.brandBlue.color
//        case .following: return Asset.Colors.brandBlue.color
//        case .muting: return Asset.Colors.alertYellow.color
//        case .blocked: return Asset.Colors.brandBlue.color
//        case .blocking: return Asset.Colors.danger.color
//        case .suspended: return Asset.Colors.brandBlue.color
//        case .edit: return Asset.Colors.brandBlue.color
//        case .editing: return Asset.Colors.brandBlue.color
//        case .updating: return Asset.Colors.brandBlue.color
//        }
//    }
//
}
