//
//  AvatarBarButtonItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

public final class AvatarBarButtonItem: UIBarButtonItem {

    public static let avatarButtonSize = CGSize(width: 30, height: 30)

    public let avatarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: avatarButtonSize.width).priority(.defaultHigh),
            button.heightAnchor.constraint(equalToConstant: avatarButtonSize.height).priority(.defaultHigh),
        ])
        return button
    }()
    
    public override init() {
        super.init()
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AvatarBarButtonItem {
    
    private func _init() {
        customView = avatarButton
    }
    
}
