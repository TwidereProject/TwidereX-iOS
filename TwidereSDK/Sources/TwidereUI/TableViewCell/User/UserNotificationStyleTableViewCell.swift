//
//  UserNotificationStyleTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

public final class UserNotificationStyleTableViewCell: UserTableViewCell {
    
    let separator = SeparatorLineView()
    
    public override func _init() {
        super._init()
        
        userView.setup(style: .notification)

        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: userView.nameLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
    }
    
}
