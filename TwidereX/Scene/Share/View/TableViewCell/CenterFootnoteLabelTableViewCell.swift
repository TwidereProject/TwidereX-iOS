//
//  CenterFootnoteLabelTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class CenterFootnoteLabelTableViewCell: UITableViewCell {
    
    let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = " "
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CenterFootnoteLabelTableViewCell {
    
    private func _init() {
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.required - 1),
        ])
    }
    
}
