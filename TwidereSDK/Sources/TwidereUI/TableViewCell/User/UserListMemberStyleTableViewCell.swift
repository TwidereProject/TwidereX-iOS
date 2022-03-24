//
//  UserListMemberStyleTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-3-24.
//

import UIKit

public final class UserListMemberStyleTableViewCell: UserTableViewCell {
    
    let separator = SeparatorLineView()
    
    public override func _init() {
        super._init()
        
        userView.setup(style: .listMember)

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
