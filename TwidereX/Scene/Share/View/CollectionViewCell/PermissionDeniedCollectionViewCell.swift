//
//  PermissionDeniedCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class PermissionDeniedCollectionViewCell: UICollectionViewCell {
    
    let permissionDeniedHeaderView = PermissionDeniedHeaderView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PermissionDeniedCollectionViewCell {
    
    private func _init() {
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

