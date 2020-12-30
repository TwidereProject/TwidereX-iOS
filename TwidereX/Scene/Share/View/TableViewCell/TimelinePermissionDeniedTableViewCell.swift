//
//  TimelinePermissionDeniedTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TimelinePermissionDeniedTableViewCell: UITableViewCell {
    
    let permissionDeniedHeaderView = PermissionDeniedHeaderView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelinePermissionDeniedTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        permissionDeniedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(permissionDeniedHeaderView)
        NSLayoutConstraint.activate([
            permissionDeniedHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            permissionDeniedHeaderView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            permissionDeniedHeaderView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            permissionDeniedHeaderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}
