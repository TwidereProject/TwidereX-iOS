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

public class UserTableViewCell: UITableViewCell {
        
    let logger = Logger(subsystem: "UserTableViewCell", category: "View")
            
    public weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?

    public override func prepareForReuse() {
        super.prepareForReuse()
        
        contentConfiguration = nil
        userViewTableViewCellDelegate = nil
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        // selectionStyle = .none
    }
    
}

// MARK: - UserViewContainerTableViewCell
extension UserTableViewCell: UserViewContainerTableViewCell { }

// MARK: - UserViewDelegate
extension UserTableViewCell: UserViewDelegate { }
