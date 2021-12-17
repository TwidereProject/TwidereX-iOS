//
//  FriendshipButton.swift
//  FriendshipButton
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

public final class FriendshipButton: UIButton {
        
    private(set) var relationship: Relationship = .follow
    
    public var titleFont: UIFont = .preferredFont(forTextStyle: .headline) {
        didSet { setNeedsUpdateConfiguration() }
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

extension FriendshipButton {
    
    private func _init() {
        configure(relationship: relationship)
    }
    
    public override func updateConfiguration() {
        super.updateConfiguration()
        
        configure(relationship: relationship)
    }
    
    public func configure(relationship: Relationship) {
        self.relationship = relationship
        
        var configuration = UIButton.Configuration.plain()
        configuration.cornerStyle = .capsule    // why capsule
        configuration.attributedTitle = {
            var attributedString = AttributedString(relationship.title)
            attributedString.font = titleFont
            return attributedString
        }()
        configuration.baseForegroundColor = baseForegroundColor(for: relationship)
        configuration.background = background(for: relationship)
        self.configuration = configuration
    }
    
}

extension FriendshipButton {

    private func background(for relationship: Relationship) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        let alpha: CGFloat = isHighlighted ? 0.5 : 1.0
        
        switch relationship {
        case .isMyself, .followingBy, .none:
            break
        case .follow, .request:
            background.backgroundColor = .clear
            background.strokeColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
            
        case .pending, .following:
            background.backgroundColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeColor = Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        case .muting:
            background.backgroundColor = Asset.Colors.Theme.vulcan.color.withAlphaComponent(alpha)
            background.strokeColor = Asset.Colors.Theme.vulcan.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        case .blockingBy, .blocking, .suspended:
            background.backgroundColor = Asset.Colors.Tint.pink.color.withAlphaComponent(alpha)
            background.strokeColor = Asset.Colors.Tint.pink.color.withAlphaComponent(alpha)
            background.strokeWidth = 1
        }
        return background
    }
    
    private func baseForegroundColor(for relationship: Relationship) -> UIColor {
        let alpha: CGFloat = isHighlighted ? 0.5 : 1.0
        switch relationship {
        case .isMyself, .followingBy, .none:
            return .clear
        case .follow, .request:
            return Asset.Colors.Theme.daylight.color.withAlphaComponent(alpha)
        case .pending, .following:
            return .white
        case .muting:
            return .white
        case .blockingBy, .blocking, .suspended:
            return .white
        }
    }

}
