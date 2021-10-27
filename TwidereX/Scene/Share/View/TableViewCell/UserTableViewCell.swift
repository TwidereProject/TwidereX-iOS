//
//  UserTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

class UserTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "UserTableViewCell", category: "UI")
    
    let userView = UserView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        userView.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        userView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userView)
        NSLayoutConstraint.activate([
            userView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            userView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: userView.bottomAnchor, constant: 16).priority(.defaultHigh),
        ])
    }
    
}
