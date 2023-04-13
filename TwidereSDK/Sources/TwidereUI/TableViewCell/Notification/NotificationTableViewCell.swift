//
//  NotificationTableViewCell.swift
//  
//
//  Created by MainasuK on 2023/4/11.
//

import os.log
import UIKit

public final class NotificationTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "View")
    
    public weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
    public weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
    public var viewModel: NotificationView.ViewModel?
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        contentConfiguration = nil
        statusViewTableViewCellDelegate = nil
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
    
}

extension NotificationTableViewCell {
    
    private func _init() {
        selectionStyle = .none
    }
    
}

// MARK: - StatusViewContainerTableViewCell
extension NotificationTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension NotificationTableViewCell: StatusViewDelegate { }

// MARK: - UserViewContainerTableViewCell
extension NotificationTableViewCell: UserViewContainerTableViewCell { }

// MARK: - UserViewDelegate
extension NotificationTableViewCell: UserViewDelegate { }
