//
//  MentionPickTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-14.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class MentionPickTableViewCell: UITableViewCell {
    
    var observations = Set<NSKeyValueObservation>()
    
    let userBriefInfoView = UserBriefInfoView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MentionPickTableViewCell {
    
    private func _init() {
        userBriefInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userBriefInfoView)
        NSLayoutConstraint.activate([
            userBriefInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userBriefInfoView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: userBriefInfoView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userBriefInfoView.bottomAnchor, constant: 16).priority(.defaultHigh),
        ])
        
        userBriefInfoView.checkmarkButton.isHidden = false
    }
    
}
