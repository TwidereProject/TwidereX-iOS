//
//  AvatarBarButtonItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class AvatarBarButtonItem: UIBarButtonItem {

    static let avatarButtonSize = CGSize(width: 30, height: 30)

    let avatarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: avatarButtonSize.width).priority(.defaultHigh),
            button.heightAnchor.constraint(equalToConstant: avatarButtonSize.height).priority(.defaultHigh),
        ])
        return button
    }()
    
    override init() {
        super.init()
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AvatarBarButtonItem {
    
    private func _init() {
        customView = avatarButton
    }
    
}

//extension AvatarBarButtonItem: AvatarConfigurableView {
//    static var configurableAvatarImageViewSize: CGSize { return avatarButtonSize }
//    var configurableAvatarImageView: UIImageView? { return nil }
//    var configurableAvatarButton: UIButton? { return avatarButton }
//    var configurableVerifiedBadgeImageView: UIImageView? { return nil }
//}
