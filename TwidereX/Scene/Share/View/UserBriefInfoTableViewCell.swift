//
//  UserBriefInfoTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class UserBriefInfoTableViewCell: UITableViewCell {
    
    let userBrifeInfoView = UserBriefInfoView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension UserBriefInfoTableViewCell {
    
    private func _init() {
        userBrifeInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userBrifeInfoView)
        NSLayoutConstraint.activate([
            userBrifeInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userBrifeInfoView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: userBrifeInfoView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userBrifeInfoView.bottomAnchor, constant: 16),
        ])
    }
    
}
