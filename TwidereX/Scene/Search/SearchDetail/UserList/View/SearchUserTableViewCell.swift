//
//  SearchUserTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol SearchUserTableViewCellDelegate: class {
    func userBriefInfoTableViewCell(_ cell: SearchUserTableViewCell, followActionButtonPressed button: FollowActionButton)
}

final class SearchUserTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SearchUserTableViewCellDelegate?
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

extension SearchUserTableViewCell {
    
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
        
        userBriefInfoView.followActionButton.isHidden = false
        userBriefInfoView.followActionButton.addTarget(self, action: #selector(SearchUserTableViewCell.followActionButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension SearchUserTableViewCell {
    
    @objc private func followActionButtonPressed(_ sender: FollowActionButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        delegate?.userBriefInfoTableViewCell(self, followActionButtonPressed: sender)
    }
    
    
}
