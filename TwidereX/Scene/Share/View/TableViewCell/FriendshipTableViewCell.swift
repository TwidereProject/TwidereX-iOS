//
//  FriendshipTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class FriendshipTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let userBriefInfoView = UserBriefInfoView()
    let separatorLine = UIView.separatorLine
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        userBriefInfoView.avatarImageView.af.cancelImageRequest()
        userBriefInfoView.avatarImageView.kf.cancelDownloadTask()
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

extension FriendshipTableViewCell {
    
    private func _init() {
        userBriefInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userBriefInfoView)
        NSLayoutConstraint.activate([
            userBriefInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userBriefInfoView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: userBriefInfoView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userBriefInfoView.bottomAnchor, constant: 16),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: userBriefInfoView.nameLabel.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        
        if #available(iOS 14.0, *) {
            userBriefInfoView.menuButton.isHidden = false
        }
    }
    
}
