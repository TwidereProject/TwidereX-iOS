//
//  TrendTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-28.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

import UIKit
import MetaTextKit

final class TrendTableViewCell: UITableViewCell {
    
    let metaLabel = MetaLabel(style: .searchHistoryTitle)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TrendTableViewCell {
    
    private func _init() {
        accessoryType = .disclosureIndicator
        
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metaLabel)
        NSLayoutConstraint.activate([
            metaLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            metaLabel.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 11),
        ])
        
        metaLabel.isUserInteractionEnabled = false
    }
    
}
