//
//  ButtonTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class ButtonTableViewCell: UITableViewCell {
    
    let button: UIButton = {
        let button = UIButton(type: .system)
        return button
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

extension ButtonTableViewCell {
    private func _init() {
        backgroundColor = .clear

        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.required - 1),
        ])
        
        button.isUserInteractionEnabled = false
    }
}
