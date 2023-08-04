//
//  FollowActionButton.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-2.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

final class FollowActionButton: UIButton {
    
    static let buttonSize = CGSize(width: 80, height: 24)
    var style: Style = .follow {
        didSet {
            followActionButtonStyleDidChanged(to: style)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            layer.borderColor = isHighlighted ? Asset.Colors.hightLight.color.withAlphaComponent(0.5).cgColor : Asset.Colors.hightLight.color.cgColor
        }
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

extension FollowActionButton {
    
    private func _init() {
        layer.masksToBounds = true
        layer.cornerRadius = FollowActionButton.buttonSize.height * 0.5
        layer.borderWidth = 1
        layer.borderColor = Asset.Colors.hightLight.color.cgColor
        titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        setTitle(L10n.Common.Controls.Friendship.Actions.follow, for: .normal)
        setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        setTitleColor(Asset.Colors.hightLight.color.withAlphaComponent(0.5), for: .highlighted)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height * 0.5
    }

}

extension FollowActionButton {
    enum Style {
        case follow
        case pending
        case following
    }
    
    private func followActionButtonStyleDidChanged(to style: Style) {
        let title: String
        let (titleColor, titleHighlightColor): (UIColor, UIColor)
        let (backgroundImage, backgroundHighlightImage): (UIImage?, UIImage?)
        let borderWidth: CGFloat
        switch style {
        case .follow:
            title = L10n.Common.Controls.Friendship.Actions.follow
            (titleColor, titleHighlightColor) = (Asset.Colors.hightLight.color, Asset.Colors.hightLight.color.withAlphaComponent(0.5))
            (backgroundImage, backgroundHighlightImage) = (nil, nil)
            borderWidth = 1
        case .pending:
            title = L10n.Common.Controls.Friendship.Actions.pending
            (titleColor, titleHighlightColor) = (Asset.Colors.hightLight.color, Asset.Colors.hightLight.color.withAlphaComponent(0.5))
            (backgroundImage, backgroundHighlightImage) = (nil, nil)
            borderWidth = 1
        case .following:
            title = L10n.Common.Controls.Friendship.Actions.following
            (titleColor, titleHighlightColor) = (.white, .white)
            (backgroundImage, backgroundHighlightImage) = (UIImage.placeholder(color: Asset.Colors.hightLight.color), UIImage.placeholder(color: Asset.Colors.hightLight.color.withAlphaComponent(0.5)))
            borderWidth = 1
        }
        setTitle(title, for: .normal)
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleHighlightColor, for: .highlighted)
        setBackgroundImage(backgroundImage, for: .normal)
        setBackgroundImage(backgroundHighlightImage, for: .highlighted)
        layer.borderWidth = borderWidth
    }
}
