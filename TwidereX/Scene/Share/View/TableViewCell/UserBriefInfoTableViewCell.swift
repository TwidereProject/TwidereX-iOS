//
//  UserBriefInfoTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol UserBriefInfoTableViewCellDelegate: class {
    func userBriefInfoTableViewCell(_ cell: UserBriefInfoTableViewCell, followActionButtonPressed button: FollowActionButton)
}

final class UserBriefInfoTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: UserBriefInfoTableViewCellDelegate?
    let userBriefInfoView = UserBriefInfoView()
    
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

extension UserBriefInfoTableViewCell {
    
    private func _init() {
        userBriefInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userBriefInfoView)
        NSLayoutConstraint.activate([
            userBriefInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userBriefInfoView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: userBriefInfoView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userBriefInfoView.bottomAnchor, constant: 16),
        ])
        
        userBriefInfoView.followActionButton.addTarget(self, action: #selector(UserBriefInfoTableViewCell.followActionButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension UserBriefInfoTableViewCell {
    
    @objc private func followActionButtonPressed(_ sender: FollowActionButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        delegate?.userBriefInfoTableViewCell(self, followActionButtonPressed: sender)
    }
    
    
}
