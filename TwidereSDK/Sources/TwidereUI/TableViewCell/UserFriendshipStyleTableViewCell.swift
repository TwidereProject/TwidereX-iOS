//
//  UserFriendshipStyleTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

public final class UserFriendshipStyleTableViewCell: UserTableViewCell {
    
    let separator = SeparatorLineView()
    
    public override func _init() {
        super._init()
        
        userView.setup(style: .friendship)

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
