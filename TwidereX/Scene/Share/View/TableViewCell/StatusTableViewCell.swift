//
//  StatusTableViewCell.swift
//  StatusTableViewCell
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class StatusTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let statusView = StatusView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.prepareForReuse()
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
    
}

extension StatusTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}
