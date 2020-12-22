//
//  AccountListTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol AccountListTableViewCellDelegate: class {
    func accountListTableViewCell(_ cell: AccountListTableViewCell, menuButtonPressed button: UIButton)
}

final class AccountListTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: AccountListTableViewCellDelegate?
    let userBriefInfoView = UserBriefInfoView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AccountListTableViewCell {
    
    private func _init() {
        userBriefInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userBriefInfoView)
        NSLayoutConstraint.activate([
            userBriefInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userBriefInfoView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: userBriefInfoView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userBriefInfoView.bottomAnchor, constant: 16).priority(.defaultHigh),
        ])
        
        userBriefInfoView.menuButton.isHidden = false
        userBriefInfoView.menuButton.addTarget(self, action: #selector(AccountListTableViewCell.menuButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension AccountListTableViewCell {
    
    @objc private func menuButtonPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        delegate?.accountListTableViewCell(self, menuButtonPressed: sender)
    }
    
    
}
