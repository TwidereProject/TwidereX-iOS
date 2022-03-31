//
//  UserFriendshipStyleTableViewCell.swift
//  
//
//  Created by MainasuK on 2021-12-3.
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
